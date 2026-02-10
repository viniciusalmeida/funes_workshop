class VirtualDebtProjection < Funes::Projection
  include InterestCalculator

  materialization_model Debt::Virtual

  interpretation_for Debt::Issued do |state, issuance_event|
    state.assign_attributes(principal: issuance_event.principal,
                            interest_rate: issuance_event.interest_rate,
                            interest_rate_base: issuance_event.interest_rate_base,
                            present_value: issuance_event.principal,
                            contract_date: issuance_event.at,
                            last_payment_at: nil)
    state
  end

  interpretation_for Debt::PaymentReceived do |state, payment_received_event|
    interest = simple_interest(state.principal, daily_interest_rate(state.interest_rate, state.interest_rate_base),
                               days_between(state.last_payment_at || state.contract_date, payment_received_event.at))
    new_principal = (state.principal - (payment_received_event.amount - interest)).round(2)
    payment_received_event
      .errors.add(:amount, "must be greater than the accrued interest.") if interest > payment_received_event.amount

    state.assign_attributes(principal: new_principal, present_value: new_principal,
                            last_payment_at: payment_received_event.at)
    state
  end

  final_state do |state, as_of|
    calculated_present_value = present_value(state.principal,
                                             daily_interest_rate(state.interest_rate, state.interest_rate_base),
                                             days_between(state.last_payment_at || state.contract_date,
                                                          as_of.to_date))

    state.assign_attributes(present_value: calculated_present_value.round(2))
    state
  end

  private
    def self.present_value(principal, daily_rate, days)
      principal + simple_interest(principal, daily_rate, days)
    end
end
