require "test_helper"

class MoneyTypeTest < ActiveSupport::TestCase
  subject = MoneyType.new

  describe "#cast" do
    test "returns nil for nil and blank strings" do
      assert_nil subject.cast(nil)
      assert_nil subject.cast("")
      assert_nil subject.cast("  ")
    end

    test "passes Money through untouched" do
      money = Money.from_amount(12.34)

      assert_same money, subject.cast(money)
    end

    test "parses strings as whole currency units" do
      assert_equal Money.from_amount(5000.50), subject.cast("5000.50")
    end

    test "casts numerics as whole currency units, not cents" do
      assert_equal Money.from_amount(500), subject.cast(500)
      assert_equal Money.from_amount(500.5), subject.cast(500.5)
      assert_equal Money.from_amount(500.5), subject.cast(BigDecimal("500.5"))
    end

    test "rebuilds Money from its own as_json shape with string keys" do
      assert_equal Money.new(577294, "USD"), subject.cast({ "cents" => 577294, "currency" => "USD" })
    end

    test "rebuilds Money from a symbol-keyed hash" do
      assert_equal Money.new(577294, "USD"), subject.cast({ cents: 577294, currency: "USD" })
    end
  end

  describe "Money#as_json" do
    test "serializes to the event payload shape" do
      assert_equal({ "cents" => 100000, "currency" => "USD" }, Money.from_amount(1000).as_json)
    end

    test "round-trips through cast" do
      money = Money.from_amount(5772.94)

      assert_equal money, subject.cast(money.as_json)
    end
  end
end
