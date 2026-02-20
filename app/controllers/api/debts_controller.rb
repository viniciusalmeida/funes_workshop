class Api::DebtsController < Api::BaseController
  NANO_ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

  def create
    idx = Nanoid.generate(size: 8, alphabet: NANO_ALPHABET)
    event = Debt::Issued.new(debt_params)
    stream = DebtEventStream.for(idx)
    stream.append(event)

    return render json: { errors: event.errors.full_messages }, status: :unprocessable_entity unless event.persisted?

    render json: debt_json(idx, stream.projected_with(VirtualDebtProjection)), status: :created
  end

  def show
    stream = DebtEventStream.for(params[:id])
    render json: debt_json(params[:id], stream.projected_with(VirtualDebtProjection))
  end

  private
    def debt_params
      params.require(:debt).permit(:principal, :interest_rate, :interest_rate_base, :at)
    end
end
