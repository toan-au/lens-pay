class Api::V1::NetworkDisputesController < ApplicationController
  include NetworkAuthenticated

  rescue_from DisputeError::ValidationFailed do |e|
    render json: { errors: e.messages }, status: :unprocessable_content
  end

  rescue_from DisputeError::InvalidPayment,
              DisputeError::MismatchedCurrency,
              DisputeError::InvalidReason,
              DisputeError::AlreadyDisputed,
              DisputeError::AlreadyResolved do |e|
    render json: { error: e.message }, status: :unprocessable_content
  end

  def create
    params.require([ :payment_reference, :case_reference ])

    transaction = Transaction.find_by(provider_reference: params[:payment_reference])
    return render json: { error: "Payment not found" }, status: :not_found unless transaction

    result = Disputes::CreateService.call(transaction, dispute_params)
    render json: result.dispute, status: result.status
  end

  def resolve
    params.require(:case_reference)

    dispute = Dispute.find_by(provider_reference: params[:case_reference])
    return render json: { error: "Dispute not found" }, status: :not_found unless dispute

    result = Disputes::ResolveService.call(dispute, params[:outcome])
    render json: result.dispute, status: result.status
  end

  private

  def dispute_params
    params.permit(:reason, :amount, :currency, :case_reference)
  end
end
