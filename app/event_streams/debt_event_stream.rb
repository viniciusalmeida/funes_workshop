class DebtEventStream < Funes::EventStream
  consistency_projection VirtualDebtProjection
  add_transactional_projection DebtProjection
end
