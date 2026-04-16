# Projection replay throughput benchmark
#
# Measures how many VirtualDebtProjection replays/sec at stream depths 1, 5, 10, 25, 50, 100.
# The `compare!` output shows both absolute ips and relative ratios — ratios are
# machine-independent and are the primary result to communicate externally.
#
# Run locally:
#   RAILS_ENV=test rails runner bench/projection_replay.rb
#
# Run in Docker (reproducible absolute numbers):
#   docker run --rm --cpus=1 --memory=512m funes-bench rails runner bench/projection_replay.rb

require 'benchmark/ips'
require_relative 'support/stream_seeder'
include BenchSupport::StreamSeeder

GC.compact
seed_all!(:read)

streams = DEPTHS.each_with_object({}) do |depth, h|
  h[depth] = DebtEventStream.for(stream_idx(:read, depth))
end

GC.compact
GC.disable

puts "Benchmarking projection replay (warmup: 5s, measurement: 10s each)...\n\n"

Benchmark.ips do |x|
  x.config(warmup: 5, time: 10)

  DEPTHS.each do |depth|
    x.report("depth #{depth.to_s.rjust(3)}") do
      streams[depth].projected_with(VirtualDebtProjection, as_of: Time.now)
    end
  end

  x.compare!
end
