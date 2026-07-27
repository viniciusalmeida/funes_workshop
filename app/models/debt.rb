class Debt < ApplicationRecord
  self.primary_key = "idx"

  enum :status, { open: 0, repaid: 1 }

  monetize :principal_cents

  attr_accessor :daily_interest_rate
end
