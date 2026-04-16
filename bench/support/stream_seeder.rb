require 'bigdecimal'

# Shared seeding helper for benchmark scripts.
# Seeds DebtEventStream instances at controlled depths to isolate projection replay cost.
#
# Usage:
#   require_relative 'support/stream_seeder'
#   include BenchSupport::StreamSeeder
#
#   seed_all!(:read)
#   stream = DebtEventStream.for(stream_idx(:read, 10))

module BenchSupport
  module StreamSeeder
    DEPTHS    = [1, 5, 10, 25, 50, 100].freeze
    PRINCIPAL = BigDecimal('10000.00')
    RATE      = BigDecimal('0.10')
    RATE_BASE = 'yearly'.freeze
    CONTRACT  = Date.new(2010, 1, 1)

    def stream_idx(purpose, depth)
      "bench-#{purpose}-d#{depth}"
    end

    def seed_stream!(purpose, depth)
      idx  = stream_idx(purpose, depth)
      conn = ActiveRecord::Base.connection
      conn.execute("DELETE FROM event_entries WHERE idx = '#{idx}'")

      stream = DebtEventStream.for(idx)
      stream.append(Debt::Issued.new(
        principal:          PRINCIPAL,
        interest_rate:      RATE,
        interest_rate_base: RATE_BASE,
        at:                 CONTRACT
      ))

      (depth - 1).times do |i|
        payment_date = CONTRACT >> (i + 1)
        debt         = stream.projected_with(VirtualDebtProjection, at: payment_date, as_of: Time.now)
        amount       = (debt.present_value * BigDecimal('0.1')).round(2)
        stream.append(Debt::PaymentReceived.new(amount: amount, at: payment_date))
      end
    end

    def seed_all!(purpose)
      puts "Seeding depths #{DEPTHS.join(', ')} for :#{purpose}..."
      DEPTHS.each do |depth|
        print "  depth #{depth.to_s.rjust(3)}... "
        seed_stream!(purpose, depth)
        puts "ok"
      end
      puts
    end
  end
end
