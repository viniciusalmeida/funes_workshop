require "test_helper"

class InterestCalculatorTest < ActiveSupport::TestCase
  describe ".simple_interest" do
    test "calculates interest as principal times daily rate times days" do
      assert_equal 500, InterestCalculator.simple_interest(10000, 0.01, 5)
    end

    test "returns zero when days is zero" do
      assert_equal 0, InterestCalculator.simple_interest(10000, 0.01, 0)
    end
  end

  describe ".days_between" do
    test "returns the number of days between two dates" do
      assert_equal 181, InterestCalculator.days_between(Date.new(2025, 1, 1), Date.new(2025, 7, 1))
    end

    test "returns zero for the same date" do
      assert_equal 0, InterestCalculator.days_between(Date.new(2025, 1, 1), Date.new(2025, 1, 1))
    end

    test "returns positive value regardless of date order" do
      assert_equal 181, InterestCalculator.days_between(Date.new(2025, 7, 1), Date.new(2025, 1, 1))
    end
  end

  describe ".daily_interest_rate" do
    test "converts yearly rate to daily" do
      daily_rate = InterestCalculator.daily_interest_rate(0.10, "yearly")

      assert_in_delta 0.000273972, daily_rate, 0.000001
    end

    test "converts monthly rate to daily" do
      daily_rate = InterestCalculator.daily_interest_rate(0.01, "monthly")

      assert_in_delta 0.000328767, daily_rate, 0.000001
    end

    test "returns the rate as-is for daily base" do
      assert_equal BigDecimal("0.001"), InterestCalculator.daily_interest_rate(0.001, "daily")
    end
  end

  describe ".process_payment" do
    test "splits payment into accrued interest and principal reduction" do
      result = InterestCalculator.process_payment(10000, BigDecimal("0.10") / 365,
                                                  interest_accrued_since: Date.new(2025, 1, 1),
                                                  payment_amount: 5000,
                                                  payment_date: Date.new(2025, 7, 1))

      assert_equal 5495.89, result[:principal_after_payment]
      assert_equal 495.89, result[:accrued_interest]
    end

    test "zeroes out principal when payment matches present value" do
      result = InterestCalculator.process_payment(10000, BigDecimal("0.10") / 365,
                                                  interest_accrued_since: Date.new(2025, 1, 1),
                                                  payment_amount: 10495.89,
                                                  payment_date: Date.new(2025, 7, 1))

      assert_equal 0.0, result[:principal_after_payment]
    end

    test "returns negative principal when overpaying" do
      result = InterestCalculator.process_payment(10000, BigDecimal("0.10") / 365,
                                                  interest_accrued_since: Date.new(2025, 1, 1),
                                                  payment_amount: 15000,
                                                  payment_date: Date.new(2025, 7, 1))

      assert result[:principal_after_payment].negative?
    end
  end
end
