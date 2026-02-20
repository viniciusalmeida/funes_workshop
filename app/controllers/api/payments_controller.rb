class Api::PaymentsController < Api::BaseController
  def create
    stream = DebtEventStream.for(params[:debt_id])
    event = Debt::PaymentReceived.new(payment_params)
    stream.append(event)

    return render json: { errors: event.errors.full_messages }, status: :unprocessable_entity unless event.persisted?

    render json: debt_json(params[:debt_id], stream.projected_with(VirtualDebtProjection)), status: :created
  end

  private
    def payment_params
      params.require(:payment).permit(:amount, :at)
    end
end
