class Debt::Issued < Funes::Event
  attribute :principal, :decimal
  attribute :interest_rate, :decimal
  attribute :interest_rate_base, :string, default: "yearly"
  attribute :at, :date

  validates :principal, presence: true, numericality: { greater_than: 0 }
  validates :interest_rate, presence: true, numericality: { greater_than: 0 }
  validates :interest_rate_base, presence: true, inclusion: { in: %w[yearly monthly daily] }
  validates :at, presence: true
end
