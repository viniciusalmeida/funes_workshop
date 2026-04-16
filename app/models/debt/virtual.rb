class Debt::Virtual
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :principal, :decimal
  attribute :interest_rate, :decimal
  attribute :interest_rate_base, :string, default: "yearly"
  attribute :daily_rate, :decimal
  attribute :present_value, :decimal
  attribute :contract_date, :date
  attribute :last_payment_at, :date

  validates :principal, presence: true
  validates :interest_rate, presence: true, numericality: { greater_than: 0 }
  validates :interest_rate_base, presence: true, inclusion: { in: %w[yearly monthly daily] }
  validates :present_value, presence: true, numericality: { greater_than_or_equal_to: 0, message: "cannot be negative - the debt is being overpaid!" }
  validates :contract_date, presence: true
end
