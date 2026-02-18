class PaymentsController < ApplicationController
  before_action :set_event_stream

  def new
    @new_event = Debt::PaymentReceived.new
  end

  def create
    @new_event = Debt::PaymentReceived.new(event_params)
    @debt_event_stream.append(@new_event)

    return render :new, status: :unprocessable_entity unless @new_event.persisted?

    respond_to do |format|
      format.turbo_stream { @debt = @debt_event_stream.projected_with(VirtualDebtProjection) }
      format.html { redirect_to debt_path(@debt_event_stream) }
    end
  end

  private
    def event_params
      params.require(:debt_payment_received).permit(:amount, :at)
    end

    def set_event_stream
      @debt_event_stream = DebtEventStream.for(params[:debt_id])
    end
end
