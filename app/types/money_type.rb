class MoneyType < ActiveModel::Type::Value
  def type
    :money
  end

  def cast(value)
    case value
    when nil     then nil
    when Money   then value
    when Hash    then cast_hash(value)
    when String  then value.blank? ? nil : Monetize.parse(value, Money.default_currency)
    when Numeric then Money.from_amount(value, Money.default_currency)
    end
  end

  private
    def cast_hash(hash)
      hash = hash.stringify_keys
      Money.new(hash.fetch("cents"), hash.fetch("currency", Money.default_currency))
    end
end
