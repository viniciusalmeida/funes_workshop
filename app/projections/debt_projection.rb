class DebtProjection < Funes::Projection
  include InterestCalculator

  materialization_model Debt

  interpretation_for Debt::Issued do |state, issuance_event|
    state.principal = issuance_event.principal
    state.daily_interest_rate = daily_interest_rate(issuance_event.interest_rate, issuance_event.interest_rate_base)
    state.assign_attributes(status: :open,
                            contract_date: issuance_event.at)
    state
  end

  interpretation_for Debt::PaymentReceived do |state, payment_received_event|
    interest = simple_interest(state.principal, state.daily_interest_rate,
                               days_between(state.last_payment_date || state.contract_date, payment_received_event.at))
    new_principal = (state.principal - (payment_received_event.amount - interest)).round(2)

    state.principal = new_principal
    state.assign_attributes(status: new_principal.zero? ? :repaid : state.status,
                            last_payment_date: payment_received_event.at)
    state
  end
end
