class Api::BaseController < ActionController::API
  private
    def debt_json(idx, debt)
      { idx: }.merge(debt.attributes.transform_values { |value| value.is_a?(Money) ? value.to_d : value })
    end
end
