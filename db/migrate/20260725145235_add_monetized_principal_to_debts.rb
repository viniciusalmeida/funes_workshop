class AddMonetizedPrincipalToDebts < ActiveRecord::Migration[8.1]
  def change
    add_money :debts, :principal
  end
end
