class Api::V1::NetworkDisputesController < ApplicationController
  before_action :verify_network_secret

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
    transaction = Transaction.find_by(uid: params[:payment_uid])
    return render json: { error: "Payment not found" }, status: :not_found unless transaction

    result = Disputes::CreateService.call(transaction, dispute_params)
    render json: result.dispute, status: result.status
  end

  def resolve
    dispute = Dispute.find_by(uid: params[:uid])
    return render json: { error: "Dispute not found" }, status: :not_found unless dispute

    result = Disputes::ResolveService.call(dispute, params[:outcome])
    render json: result.dispute, status: result.status
  end

  private

  def verify_network_secret
    expected = ENV["NETWORK_SECRET"]
    provided = request.headers["X-Network-Secret"]

    unless expected.present? && ActiveSupport::SecurityUtils.secure_compare(provided.to_s, expected)
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def dispute_params
    params.permit(:reason, :amount, :currency)
  end
end
