require_relative 'support/stream_seeder'
include BenchSupport::StreamSeeder

seed_stream!(:smoke, 3)
stream = DebtEventStream.for(stream_idx(:smoke, 3))
debt   = stream.projected_with(VirtualDebtProjection, as_of: Time.now)
puts "depth-3 present_value: #{debt.present_value}"
puts "PASS"

ActiveRecord::Base.connection.execute("DELETE FROM event_entries WHERE idx LIKE 'bench-smoke%'")
