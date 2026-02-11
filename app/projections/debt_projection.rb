class DebtProjection < Funes::Projection
  materialization_model Debt

  interpretation_for Debt::Issued do |state, issuance_event|
    state.principal = issuance_event.principal
    state.daily_interest_rate = InterestCalculator.daily_interest_rate(issuance_event.interest_rate,
                                                                       issuance_event.interest_rate_base)
    state.assign_attributes(status: :open,
                            contract_date: issuance_event.at)
    state
  end

  interpretation_for Debt::PaymentReceived do |state, payment_received_event|
    principal_after_payment, = InterestCalculator
                                 .process_payment(state.principal, state.daily_interest_rate,
                                                  interest_accrued_since: state.last_payment_date || state.contract_date,
                                                  payment_amount: payment_received_event.amount,
                                                  payment_date: payment_received_event.at)
                                 .values_at(:principal_after_payment)

    state.principal = principal_after_payment
    state.assign_attributes(status: principal_after_payment.zero? ? :repaid : state.status,
                            last_payment_date: payment_received_event.at)
    state
  end
end
