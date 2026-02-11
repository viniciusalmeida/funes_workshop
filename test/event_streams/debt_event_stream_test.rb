require "test_helper"

class DebtEventStreamTest < ActiveSupport::TestCase
  describe "append" do
    test "persists valid event and materializes debt" do
      assert_difference -> { Funes::EventEntry.count }, 1 do
        assert_difference -> { Debt.count }, 1 do
          DebtEventStream.for("debt-001").append(Debt::Issued.new(principal: 1000, interest_rate: 0.10,
                                                                  at: Date.new(2025, 1, 1)))
        end
      end

      assert Debt.find("debt-001").open?
    end

    test "rejects payments that overpay the debt" do
      event_stream = DebtEventStream.for("debt-001")
      event_stream.append(Debt::Issued.new(principal: 1000, interest_rate: 0.10, at: Date.new(2025, 1, 1)))
      overpayment_event = Debt::PaymentReceived.new(amount: 5000, at: Date.new(2025, 2, 1))

      assert_no_difference -> { Funes::EventEntry.count } do
        event_stream.append(overpayment_event)
      end

      assert overpayment_event.invalid?
      assert_not_empty overpayment_event.errors
    end

    test "rejects payment that doesn't cover accrued interest" do
      event_stream = DebtEventStream.for("debt-001")
      event_stream.append(Debt::Issued.new(principal: 1000, interest_rate: 0.10, at: Date.new(2025, 1, 1)))
      underpayment = Debt::PaymentReceived.new(amount: 10, at: Date.new(2025, 7, 1))

      assert_no_difference -> { Funes::EventEntry.count } do
        event_stream.append(underpayment)
      end

      assert_includes underpayment.errors[:amount], "must be greater than the accrued interest.",
                      "after 6 months, accrued interest is ~$49.59, so a $10 payment should be rejected"
    end

    test "sets debt status to repaid when fully paid" do
      event_stream = DebtEventStream.for("debt-001")
      event_stream.append(Debt::Issued.new(principal: 1000, interest_rate: 0.10, at: Date.new(2025, 1, 1)))
      event_stream.append(Debt::PaymentReceived.new(amount: 1049.59, at: Date.new(2025, 7, 1)))

      assert Debt.find("debt-001").repaid?
    end

    test "sets debt status to repaid after multiple payments" do
      event_stream = DebtEventStream.for("debt-001")
      event_stream.append(Debt::Issued.new(principal: 1000, interest_rate: 0.10, at: Date.new(2025, 1, 1)))

      event_stream.append(Debt::PaymentReceived.new(amount: 500, at: Date.new(2025, 4, 1)))
      assert Debt.find("debt-001").open?,
             "first payment after 3 months covers ~$24.66 interest + $475.34 principal, debt should remain open"

      event_stream.append(Debt::PaymentReceived.new(amount: 537.74, at: Date.new(2025, 7, 1)))
      assert Debt.find("debt-001").repaid?,
             "second payment after another 3 months pays off remaining ~$524.66 principal + ~$13.08 interest"
    end
  end
end
