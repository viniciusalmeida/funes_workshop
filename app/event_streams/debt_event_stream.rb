class DebtEventStream < Funes::EventStream
  consistency_projection VirtualDebtProjection
  add_transactional_projection DebtProjection
  actual_time_attribute :at
end
