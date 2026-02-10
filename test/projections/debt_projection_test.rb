require "test_helper"

class DebtProjectionTest < ActiveSupport::TestCase
  include Funes::ProjectionTestHelper

  describe "interpretation_for Debt::Issued" do
    test "initializes debt state from issuance event" do
      issuance_date = Date.new(2025, 6, 15)
      result = interpret_event_based_on(DebtProjection,
                                        Debt::Issued.new(principal: 1000.00, interest_rate: 0.12, at: issuance_date),
                                        Debt.new)

      assert_equal issuance_date, result.contract_date
      assert result.open?
    end
  end

  describe "interpretation_for Debt::PaymentReceived" do
    test "keeps debt open when payment does not zero out principal" do
      initial_state = Debt.new(daily_interest_rate: BigDecimal(0.00027397), contract_date: Date.new(2025, 1, 1),
                               principal: 10000, status: :open)
      result = interpret_event_based_on(DebtProjection,
                                        Debt::PaymentReceived.new(amount: 5000, at: Date.new(2025, 7, 1)),
                                        initial_state)

      assert result.open?
      assert_equal Date.new(2025, 7, 1), result.last_payment_date
    end

    test "sets status to repaid when second payment zeroes out principal" do
      post_first_payment_state = Debt.new(daily_interest_rate: BigDecimal(0.00027397),
                                          contract_date: Date.new(2025, 1, 1), principal: 5495.89,
                                          last_payment_date: Date.new(2025, 7, 1), status: :open)
      result = interpret_event_based_on(DebtProjection,
                                        Debt::PaymentReceived.new(amount: 5772.94, at: Date.new(2026, 1, 1)),
                                        post_first_payment_state)

      assert_equal 0.00, result.principal
      assert result.repaid?
      assert_equal Date.new(2026, 1, 1), result.last_payment_date
    end
  end
end
