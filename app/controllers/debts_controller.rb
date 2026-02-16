class DebtsController < ApplicationController
  before_action :load_debts, only: [ :index, :create ]

  NANO_ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

  def create
    idx = Nanoid.generate(size: 8, alphabet: NANO_ALPHABET)
    @event = Debt::Issued.new(event_params)
    stream = DebtEventStream.for(idx)
    stream.append(@event)

    if @event.persisted?
      @new_debt = Debt.find(idx)
      @new_event = Debt::Issued.new
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to debt_path(stream) }
      end
    else
      @new_event = @event
      render :index, status: :unprocessable_entity
    end
  end

  def show
    @debt_id = params[:id]
    @debt = DebtEventStream.for(@debt_id)
                           .projected_with(VirtualDebtProjection)
  end

  def index
    @new_event = Debt::Issued.new
  end

  private
    def event_params
      params.require(:debt_issued).permit(:principal, :interest_rate, :interest_rate_base, :at)
    end

    def load_debts
      @debts = Debt.all
    end
end
