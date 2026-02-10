module InterestCalculator
  extend ActiveSupport::Concern

  class_methods do
    def simple_interest(principal, daily_rate, days)
      principal * daily_rate * days
    end

    def days_between(first_date, second_date)
      (first_date - second_date).abs.to_i
    end

    def daily_interest_rate(interest_rate, interest_rate_base)
      rate = BigDecimal(interest_rate)

      case interest_rate_base
      when "yearly"  then rate / 365
      when "monthly" then rate * 12 / 365
      when "daily"   then rate
      end
    end
  end
end
