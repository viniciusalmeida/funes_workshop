require "test_helper"

class VirtualDebtProjectionTest < ActiveSupport::TestCase
  include Funes::ProjectionTestHelper

  describe "interpretation_for Debt::Issued" do
    test "initializes debt state from issuance event" do
      issuance_date = Date.new(2025, 6, 15)
      result = interpret_event_based_on(VirtualDebtProjection,
                                        Debt::Issued.new(principal: 1000.00, interest_rate: 0.12, at: issuance_date),
                                        Debt::Virtual.new)

      assert_equal 1000.00, result.principal
      assert_equal 0.12, result.interest_rate
      assert_equal "yearly", result.interest_rate_base
      assert_equal 1000.00, result.present_value
      assert_equal issuance_date, result.contract_date
      assert_nil result.last_payment_at
    end
  end

  describe "interpretation_for Debt::PaymentReceived" do
    test "allocates payment to accrued interest first, then reduces principal" do
      initial_state = Debt::Virtual.new(interest_rate: 0.10, contract_date: Date.new(2025, 1, 1), principal: 10000)
      result = interpret_event_based_on(VirtualDebtProjection,
                                        Debt::PaymentReceived.new(amount: 5000, at: Date.new(2025, 7, 1)),
                                        initial_state)

      assert_equal 5495.89, result.principal, "reduces principal by payment minus accrued interest"
      assert_equal result.principal, result.present_value,
                   "resets present value to principal after full interest amortization"
      assert_equal result.last_payment_at, Date.new(2025, 7, 1), "records payment date as last amortization"
    end

    test "repays the debt when the payment matches the present value" do
      initial_state = Debt::Virtual.new(interest_rate: 0.10, contract_date: Date.new(2025, 1, 1), principal: 10000)
      result = interpret_event_based_on(VirtualDebtProjection,
                                        Debt::PaymentReceived.new(amount: 10495.89, at: Date.new(2025, 7, 1)),
                                        initial_state)

      assert_equal 0.00, result.principal, "sets the principal to 0"
      assert_equal 0.00, result.present_value, "sets the present value to 0 since there is no remaining principal " \
                                               "or interest after the repayment"
      assert_equal result.last_payment_at, Date.new(2025, 7, 1), "records payment date as last amortization"
    end

    test "returns invalid state when overpayment causes negative principal" do
      initial_state = Debt::Virtual.new(interest_rate: 0.10, contract_date: Date.new(2025, 1, 1), principal: 10000)
      result = interpret_event_based_on(VirtualDebtProjection,
                                        Debt::PaymentReceived.new(amount: 15000, at: Date.new(2025, 7, 1)),
                                        initial_state)

      assert result.principal.negative?, "payment led the debt state to inform a negative principal"
      assert result.errors["principal"].include?("must be greater than or equal to 0"),
             "sets the proper error message in the model"
    end

    test "returns invalid event when the payment amount doesn't cover the accrued interest" do
      initial_state = Debt::Virtual.new(interest_rate: 0.10, contract_date: Date.new(2025, 1, 1), principal: 10000)
      event = Debt::PaymentReceived.new(amount: 10, at: Date.new(2025, 7, 1))
      interpret_event_based_on(VirtualDebtProjection, event, initial_state)

      assert_equal event.errors[:amount], [ "must be greater than the accrued interest." ]
    end
  end

  describe "final_state" do
    describe "when there is only interest accrual - no payments" do
      test "calculates the correct present value after one full year of accrued interest" do
        initial_state = Debt::Virtual.new(interest_rate: 0.10, contract_date: Date.new(2025, 1, 1), principal: 10000)
        result = apply_final_state_based_on(VirtualDebtProjection, initial_state, Time.new(2026, 1, 1))

        assert_equal 11000.00, result.present_value, "accrues the interest for the entire period"
      end
    end

    describe "when there was a payment" do
      test "calculates interest from the last amortization date, not contract date" do
        post_payment_state = Debt::Virtual.new(interest_rate: 0.10, contract_date: Date.new(2025, 1, 1),
                                               principal: 5495.89, last_payment_at: Date.new(2025, 7, 1))

        assert_equal 5772.94, apply_final_state_based_on(VirtualDebtProjection, post_payment_state,
                                                         Time.new(2026, 1, 1)).present_value,
                     "uses the proper residual principal (5,495.89) and accrues the interest for the period " \
                     "that starts at the last amortization (277.05)"
      end
    end
  end
end
