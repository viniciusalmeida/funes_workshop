# CPU flamegraph for VirtualDebtProjection replay
#
# Profiles 1_000 replay iterations on a depth-50 stream.
# Shows the time split between: SQLite query, ActiveRecord result mapping,
# Ruby projection logic, and InterestCalculator calls.
#
# Run locally:
#   RAILS_ENV=test rails runner bench/profile_projection.rb
#   stackprof --d3-flamegraph tmp/stackprof-projection.dump > tmp/flamegraph.html
#   open tmp/flamegraph.html
#
# Run in Docker (volume-mount tmp/ to retrieve the dump):
#   docker run --rm --cpus=1 --memory=512m \
#     -v "$(pwd)/tmp:/rails/tmp" funes-bench rails runner bench/profile_projection.rb
#   stackprof --d3-flamegraph tmp/stackprof-projection.dump > tmp/flamegraph.html
#   open tmp/flamegraph.html

require 'stackprof'
require_relative 'support/stream_seeder'
include BenchSupport::StreamSeeder

PROFILE_DEPTH      = 50
PROFILE_ITERATIONS = 1_000
DUMP_PATH          = Rails.root.join('tmp/stackprof-projection.dump').to_s

FileUtils.mkdir_p(File.dirname(DUMP_PATH))

puts "Seeding depth-#{PROFILE_DEPTH} stream..."
GC.compact
seed_stream!(:profile, PROFILE_DEPTH)
stream = DebtEventStream.for(stream_idx(:profile, PROFILE_DEPTH))

puts "Warming up (50 iterations)..."
50.times { stream.projected_with(VirtualDebtProjection, as_of: Time.now) }
GC.compact

puts "Profiling #{PROFILE_ITERATIONS} replays at depth #{PROFILE_DEPTH}...\n\n"

StackProf.run(mode: :cpu, out: DUMP_PATH, interval: 100, raw: true) do
  PROFILE_ITERATIONS.times do
    stream.projected_with(VirtualDebtProjection, as_of: Time.now)
  end
end

report = StackProf::Report.new(Marshal.load(File.binread(DUMP_PATH)))

puts "Top 20 methods by self time:\n\n"
report.print_text(false, 20)

puts "\nDump written to: #{DUMP_PATH}"
puts "\nNext steps:"
puts "  stackprof --d3-flamegraph #{DUMP_PATH} > tmp/flamegraph.html"
puts "  open tmp/flamegraph.html"
