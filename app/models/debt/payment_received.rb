class Debt::PaymentReceived < Funes::Event
  attribute :amount, :money
  attribute :at, :date

  validates :amount, presence: true, comparison: { greater_than: 0, allow_nil: true }
  validates :at, presence: true
end
