class Debt::PaymentReceived < Funes::Event
  attribute :amount, :decimal
  attribute :at, :date

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :at, presence: true
end
