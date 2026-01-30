class VirtualDebtProjection < Funes::Projection
  materialization_model Debt::Virtual

  interpretation_for Debt::Issued do |state, issuance_event|
    state.assign_attributes(principal: issuance_event.principal,
                            interest_rate: issuance_event.interest_rate,
                            interest_rate_base: issuance_event.interest_rate_base,
                            present_value: issuance_event.principal,
                            contract_date: issuance_event.at)
    state
  end

  final_state do |state, as_of|
    present_value = accrue_simple_interest(state.principal,
                                           daily_interest_rate(state.interest_rate, state.interest_rate_base),
                                           days_between(state.contract_date, as_of.to_date)).round(2)
    state.assign_attributes(present_value:)
    state
  end

  private
    def self.accrue_simple_interest(principal, interest, periods)
      (1 + (interest * periods)) * principal
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
