class MoneyType < ActiveModel::Type::Value
  def type
    :money
  end

  # Strings arrive from form params, so they stay lenient: unparseable input becomes zero and is
  # rejected by the numeric validations, exactly as it was when these attributes were :decimal.
  # Every other unsupported type can only come from a bug or a corrupt payload, so it raises rather
  # than casting to nil and resurfacing as a misleading "can't be blank".
  def cast(value)
    case value
    when nil     then nil
    when Money   then value
    when Hash    then cast_hash(value)
    when String  then value.blank? ? nil : Monetize.parse(value, Money.default_currency)
    when Numeric then Money.from_amount(value, Money.default_currency)
    else raise ArgumentError, "cannot cast #{value.class} to Money: #{value.inspect}"
    end
  end

  private
    def cast_hash(hash)
      hash = hash.stringify_keys
      Money.new(hash.fetch("cents"), hash.fetch("currency", Money.default_currency))
    end
end
