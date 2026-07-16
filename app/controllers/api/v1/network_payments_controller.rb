class Api::V1::NetworkPaymentsController < ApplicationController
  include NetworkAuthenticated

  rescue_from PaymentError::InvalidTransition do |e|
    render json: { error: e.message }, status: :unprocessable_content
  end

  def confirm
    params.require(:reference)

    transaction = Transaction.find_by(provider_reference: params[:reference])
    return render json: { error: "Payment not found" }, status: :not_found unless transaction

    result = Payments::ConfirmService.call(transaction)
    render json: result.transaction, status: result.status
  end
end
