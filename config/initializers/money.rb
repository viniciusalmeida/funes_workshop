MoneyRails.configure do |config|
  config.default_currency = :usd
  config.rounding_mode = BigDecimal::ROUND_HALF_UP
  config.locale_backend = :currency
  config.no_cents_if_whole = false
end

# Funes::Event#persist! writes raw `attributes` into the event entry's JSON column, so it never
# reaches MoneyType#serialize - the wire shape has to come from Money itself. The counterpart is
# MoneyType#cast_hash, which reads this shape back on replay; the two have to change together.
#
# This is global, so it also governs Money anywhere else JSON is rendered. Api::BaseController
# deliberately unwraps to a decimal instead, keeping the public API on its pre-money-rails contract.
class Money
  def as_json(_options = nil)
    { "cents" => cents, "currency" => currency.iso_code }
  end
end

module MoneyAwareFunesInspection
  private
    def format_for_inspect(name, value)
      value.is_a?(Money) ? value.format : super
    end
end

Rails.application.config.to_prepare do
  ActiveModel::Type.register(:money, MoneyType)
  Funes::Event.prepend(MoneyAwareFunesInspection)
end
