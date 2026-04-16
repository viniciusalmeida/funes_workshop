# In-Process Benchmark Results — funes-rails Projection Replay

## Measurement approach

Earlier k6 HTTP load tests revealed that Puma's thread pool (3 threads, ~174 RPS ceiling) saturates before the projection replay cost becomes observable — every request spends ~500ms waiting for a thread, which completely masks the ~1ms O(n) signal. To measure the mechanism directly, the benchmarks bypass HTTP entirely.

Each script runs via `rails runner` in `RAILS_ENV=test`, calling `DebtEventStream` and `VirtualDebtProjection` in-process. There is no server, no network, no thread queue — only the Ruby code and SQLite.

Two tools were used:
- **`benchmark-ips`** — measures iterations per second at controlled stream depths (1, 5, 10, 25, 50, 100 events), with a 5-second warmup and `compare!` output for relative ratios. Relative ratios are machine-independent even if absolute i/s vary by hardware.
- **`stackprof`** (CPU sampling, 1000 iterations at depth 50) — shows where time is actually spent inside the call, down to the method level.

For reproducible absolute numbers, the scripts are designed to run inside Docker with fixed resources:

```bash
docker build -f bench/Dockerfile.bench -t funes-bench .
docker run --rm --cpus=1 --memory=512m funes-bench \
  rails runner bench/projection_replay.rb
```

`--cpus=1` pins execution to a single core, eliminating cross-core scheduling variance. Anyone running the same image with the same flags gets comparable absolute i/s, not just the ratios.

---

## Results

### Read side — `projected_with` throughput by stream depth

| Depth | i/s | µs/call | vs depth 1 |
|---|---|---|---|
| 1 | 27,828 | 35µs | — |
| 5 | 10,110 | 99µs | 2.75x |
| 10 | 5,960 | 168µs | 4.67x |
| 25 | 2,627 | 381µs | 10.59x |
| 50 | 1,379 | 725µs | 20.19x |
| 100 | 700 | 1.43ms | 39.72x |

The O(n) shape is confirmed, but the growth is steeper than linear: 100x more events → 40x slower, with a fixed base cost accounting for the gap.

### Write side — `stream.append` on a pre-seeded stream

| Depth | avg (ms) | min (ms) | max (ms) | vs depth 1 |
|---|---|---|---|---|
| 1 | 1.24 | 1.08 | 1.45 | 1.00x |
| 5 | 1.32 | 1.17 | 1.51 | 1.07x |
| 10 | 1.68 | 1.30 | 2.18 | 1.36x |
| 25 | 2.15 | 1.76 | 2.75 | 1.74x |
| 50 | 3.11 | 2.74 | 3.45 | 2.52x |
| 100 | 4.86 | 4.53 | 5.51 | 3.93x |

The write cost grows more slowly than reads because the consistency projection runs the same O(n) replay path, but the SQLite WAL write is cheap enough to keep the total under 5ms even at depth 100.

### Where the time goes — stackprof CPU profile (depth 50, 1000 iterations)

#### Baseline (no optimizations)

| Method | % self time |
|---|---|
| GC sweeping | 58.4% |
| `BigDecimal#/` | 11.3% |
| `BigDecimal#round` | 8.0% |
| `BigDecimal#-` | 3.4% |
| `BigDecimal#*` | 2.7% |
| GC marking | 2.1% |
| `VirtualDebtProjection` block | 0.3% |

**60.6% of profiled time is GC.** The projection replay allocates a new `BigDecimal` object for each arithmetic operation on each event. At depth 50, that is hundreds of short-lived objects per call — enough to keep the GC busy for more than half the profiled time.

#### After two targeted optimizations

Two changes were applied to the workshop app:

1. **Memoize `daily_rate` on issuance** — `InterestCalculator.daily_interest_rate` was being called on every `PaymentReceived` event during replay, even though the rate never changes after issuance. The result is now computed once in the `Debt::Issued` interpretation and stored on `Debt::Virtual`, eliminating the redundant division on every subsequent event.

2. **Frozen `BigDecimal` constants** — the divisors `365` and `12` inside `daily_interest_rate` were allocated fresh on each call. They are now module-level frozen constants.

| Method | % self time (before) | % self time (after) |
|---|---|---|
| GC sweeping | 58.4% | 66.5% |
| `BigDecimal#/` | 11.3% | — |
| `BigDecimal#round` | 8.0% | 1.8% |
| `BigDecimal#-` | 3.4% | 1.8% |
| `BigDecimal#*` | 2.7% | 2.2% |
| GC marking | 2.1% | 2.4% |
| ActiveModel attribute machinery | ~5% | ~10% |
| `VirtualDebtProjection` block | 0.3% | 1.2% |

`BigDecimal#/` disappeared entirely and `#round` dropped from 8% to 1.8%. The throughput improvement was ~5–6% at deeper streams — real but modest.

**The GC percentage rose to 71.1%.** This is not a regression — total non-GC work shrank, so GC appears as a larger fraction. In absolute terms, GC samples barely changed (716 → 694). The remaining pressure comes from `ActiveModel::AttributeSet` and `assign_attributes`: every event interpretation calls `state.assign_attributes(...)`, which allocates new ActiveModel attribute wrapper objects for each field updated. At depth 50 that is 50 × N fields of wrapper allocations per replay call.

This is a gem-level boundary. `Debt::Virtual` uses ActiveModel because funes-rails requires a materialization model that follows that interface. The allocation would only go away if projection state were carried in a plain struct or mutable object rather than an ActiveModel-backed model — an architectural decision for funes-rails itself.

---

## Reproducing

```bash
git clone https://github.com/viniciusalmeida/funes_workshop
cd funes_workshop
bundle install
RAILS_ENV=test rails db:prepare

# Read throughput by depth
RAILS_ENV=test rails runner bench/projection_replay.rb

# Write-side depth cost
RAILS_ENV=test rails runner bench/event_append.rb

# CPU flamegraph
RAILS_ENV=test rails runner bench/profile_projection.rb
stackprof --d3-flamegraph tmp/stackprof-projection.dump > tmp/flamegraph.html
open tmp/flamegraph.html
```
