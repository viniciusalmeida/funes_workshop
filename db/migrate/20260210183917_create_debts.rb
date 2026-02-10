class CreateDebts < ActiveRecord::Migration[8.1]
  def change
    create_table :debts, id: false, primary_key: :idx do |t|
      t.string :idx, null: false
      t.integer :status, default: 0
      t.date :contract_date, null: false
      t.date :last_payment_date
    end

    add_index :debts, :idx, unique: true
  end
end
