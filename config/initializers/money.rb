MoneyRails.configure do |config|
  config.default_currency = :usd
  config.rounding_mode = BigDecimal::ROUND_HALF_UP
  config.locale_backend = :currency
  config.no_cents_if_whole = false
end

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
