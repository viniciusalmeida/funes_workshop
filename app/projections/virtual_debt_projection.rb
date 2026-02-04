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
    # TODO: missing concern enforcement for the minimal payment

    accrued_interest = simple_interest(state.principal,
                                       daily_interest_rate(state.interest_rate, state.interest_rate_base),
                                       days_between(state.last_payment_at || state.contract_date,
                                                    payment_received_event.at))
    paid_principal = payment_received_event.amount - accrued_interest

    state.assign_attributes(principal: (state.principal - paid_principal).round(2),
                            present_value: (state.principal - paid_principal).round(2),
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

    def self.simple_interest(principal, daily_rate, days)
      principal * daily_rate * days
    end

    def self.days_between(first_date, second_date)
      (first_date - second_date).abs.to_i
    end

    def self.daily_interest_rate(interest_rate, interest_rate_base)
      rate = BigDecimal(interest_rate)

      case interest_rate_base
      when "yearly"  then rate / 365
      when "monthly" then rate * 12 / 365
      when "daily"   then rate
      end
    end
end
