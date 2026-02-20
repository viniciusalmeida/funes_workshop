class Api::BaseController < ActionController::API
  private
    def debt_json(idx, debt)
      { idx: }.merge(debt.attributes)
    end
end
