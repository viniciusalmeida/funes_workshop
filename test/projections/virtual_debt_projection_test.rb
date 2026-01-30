require "test_helper"

class VirtualDebtProjectionTest < ActiveSupport::TestCase
  include Funes::ProjectionTestHelper

  describe "interpretation_for Debt::Issued" do
    test "initializes debt state from issuance event" do
      issuance_date = Date.new(2025, 6, 15)
      result = interpret_event_based_on(VirtualDebtProjection,
                                        Debt::Issued.new(principal: 1000.00, interest_rate: 0.12, at: issuance_date),
                                        Debt::Virtual.new)

      assert result.valid?
      assert_equal 1000.00, result.principal
      assert_equal 0.12, result.interest_rate
      assert_equal "yearly", result.interest_rate_base
      assert_equal 1000.00, result.present_value
      assert_equal issuance_date, result.contract_date
    end
  end

  describe "final_state" do
    describe "when there is only interest accrual - no payments" do
      test "calculates the correct present value after one full year of accrued interest" do
        initial_state = Debt::Virtual.new(interest_rate: 0.10, contract_date: Date.new(2025, 1, 1), principal: 10000)
        result = apply_final_state_based_on(VirtualDebtProjection, initial_state, Time.new(2026, 1, 1))

        assert_equal 11000.00, result.present_value
      end
    end
  end
end
