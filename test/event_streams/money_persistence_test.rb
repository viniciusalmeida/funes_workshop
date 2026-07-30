require "test_helper"

# Money is stored inside the event entry's JSON column, so the shape written by Money#as_json and
# the shape read back by MoneyType#cast are a contract. These tests pin both ends of it, including
# the payloads written before money-rails was adopted, which must keep replaying identically.
class MoneyPersistenceTest < ActiveSupport::TestCase
  describe "event store round-trip" do
    test "writes money as a cents/currency pair" do
      DebtEventStream.for("money-001").append(Debt::Issued.new(principal: 5772.94, interest_rate: 0.10,
                                                               at: Date.new(2025, 1, 1)))

      assert_equal({ "cents" => 577294, "currency" => "USD" }, stored_props("money-001")["principal"])
    end

    test "replays a stored event back into the same amount" do
      DebtEventStream.for("money-002").append(Debt::Issued.new(principal: 5772.94, interest_rate: 0.10,
                                                               at: Date.new(2025, 1, 1)))
      replayed = stored_entry("money-002").to_klass_instance

      assert_equal Money.from_amount(5772.94), replayed.principal
    end
  end

  describe "pre-money-rails payloads" do
    test "replays a decimal-era principal" do
      legacy = Funes::EventEntry.new(klass: "Debt::Issued",
                                     props: { "principal" => BigDecimal("5772.94").as_json,
                                              "interest_rate" => "0.1", "interest_rate_base" => "yearly",
                                              "at" => "2025-01-01" })

      assert_equal Money.from_amount(5772.94), legacy.to_klass_instance.principal,
                   "events written before money-rails store the amount as a decimal string"
    end

    test "replays a decimal-era payment amount" do
      legacy = Funes::EventEntry.new(klass: "Debt::PaymentReceived",
                                     props: { "amount" => BigDecimal("1049.59").as_json, "at" => "2025-07-01" })

      assert_equal Money.from_amount(1049.59), legacy.to_klass_instance.amount
    end
  end

  describe "event inspection" do
    test "formats money attributes as currency" do
      event = Debt::Issued.new(principal: 1000, interest_rate: 0.10, at: Date.new(2025, 1, 1))

      assert_includes event.inspect, "principal: $1,000.00"
    end
  end

  private
    def stored_entry(idx)
      Funes::EventEntry.where(idx:).order(:version).to_a.first
    end

    def stored_props(idx) = stored_entry(idx).props
end
