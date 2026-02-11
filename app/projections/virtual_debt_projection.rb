class VirtualDebtProjection < Funes::Projection
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
    new_principal, acc_interest = InterestCalculator
                                    .process_payment(state.principal,
                                                     InterestCalculator.daily_interest_rate(state.interest_rate,
                                                                                            state.interest_rate_base),
                                                     interest_accrued_since: state.last_payment_at || state.contract_date,
                                                     payment_amount: payment_received_event.amount,
                                                     payment_date: payment_received_event.at)
                                    .values_at(:principal_after_payment, :accrued_interest)

    payment_received_event
      .errors.add(:amount, "must be greater than the accrued interest.") if acc_interest > payment_received_event.amount

    state.assign_attributes(principal: new_principal, present_value: new_principal,
                            last_payment_at: payment_received_event.at)
    state
  end

  final_state do |state, as_of|
    daily_rate = InterestCalculator.daily_interest_rate(state.interest_rate, state.interest_rate_base)
    days = InterestCalculator.days_between(state.last_payment_at || state.contract_date, as_of.to_date)
    calculated_present_value = state.principal + InterestCalculator.simple_interest(state.principal, daily_rate, days)

    state.assign_attributes(present_value: calculated_present_value.round(2))
    state
  end
end
