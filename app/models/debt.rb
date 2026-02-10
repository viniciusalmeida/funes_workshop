class Debt < ApplicationRecord
  self.primary_key = "idx"

  enum :status, { open: 0, repaid: 1 }

  attr_accessor :principal, :daily_interest_rate
end
