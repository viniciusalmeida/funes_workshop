module InterestCalculator
  module_function

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

  def process_payment(principal, daily_rate, interest_accrued_since:, payment_amount:, payment_date:)
    interest = simple_interest(principal, daily_rate, days_between(interest_accrued_since, payment_date))

    { principal_after_payment: (principal - (payment_amount - interest)).round(2),
      accrued_interest: interest.round(2) }
  end
end
