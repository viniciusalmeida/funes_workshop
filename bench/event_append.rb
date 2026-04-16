# Event append throughput benchmark
#
# Measures the cost of appending a payment event to a stream with N existing events.
# The write path runs the consistency projection (a full O(n) replay) before acquiring
# the write lock — this is the write-side cost that was never benchmarked by the k6 suite.
#
# Each depth is re-seeded before measurement to hold starting depth constant.
# The stream grows by APPEND_ITERATIONS during measurement, so the avg reflects
# depths [N .. N + APPEND_ITERATIONS - 1] — acceptable for N >= 10.
#
# Run locally:
#   RAILS_ENV=test rails runner bench/event_append.rb
#
# Run in Docker:
#   docker run --rm --cpus=1 --memory=512m funes-bench rails runner bench/event_append.rb

require 'bigdecimal'
require_relative 'support/stream_seeder'
include BenchSupport::StreamSeeder

APPEND_ITERATIONS = 10

puts "Seeding write streams..."
GC.compact
seed_all!(:write)

puts "Benchmarking event append (#{APPEND_ITERATIONS} iterations per depth)...\n\n"
puts format("  %-14s  %9s  %9s  %9s  %s", "depth", "avg (ms)", "min (ms)", "max (ms)", "vs depth-1")
puts "  #{'─' * 62}"

baseline_avg = nil

DEPTHS.each do |depth|
  seed_stream!(:write, depth)
  stream       = DebtEventStream.for(stream_idx(:write, depth))
  payment_base = CONTRACT >> depth

  GC.disable
  times = []

  APPEND_ITERATIONS.times do |i|
    payment_date = payment_base >> i
    debt         = stream.projected_with(VirtualDebtProjection, at: payment_date, as_of: Time.now)
    amount       = (debt.present_value * BigDecimal('0.1')).round(2)

    t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    stream.append(Debt::PaymentReceived.new(amount: amount, at: payment_date))
    times << (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) * 1000
  end

  GC.enable

  avg          = times.sum / times.size
  baseline_avg ||= avg
  ratio        = avg / baseline_avg

  puts format("  depth %-8d  %9.2f  %9.2f  %9.2f  %.2fx",
    depth, avg, times.min, times.max, ratio)
end

puts
