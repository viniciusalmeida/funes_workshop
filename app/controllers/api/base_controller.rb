class Api::BaseController < ActionController::API
  private
    # Money#as_json is overridden globally to the {cents, currency} shape the event store needs
    # (see config/initializers/money.rb). The public API predates money-rails, so monetary values
    # are unwrapped back to plain decimals here rather than changing the response contract.
    def debt_json(idx, debt)
      { idx: }.merge(debt.attributes.transform_values { |value| value.is_a?(Money) ? value.to_d : value })
    end
end
