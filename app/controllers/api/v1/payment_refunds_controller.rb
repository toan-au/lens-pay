class Api::V1::PaymentRefundsController < ApplicationController
  wrap_parameters false

  rescue_from RefundError::ValidationFailed do |e|
    render json: { error: e.message }, status: :unprocessable_content
  end

  rescue_from RefundError::AmountExceedsRefundable do |e|
    render json: { error: e.message }, status: :unprocessable_content
  end

  rescue_from RefundError::PaymentNotSucceeded do |e|
    render json: { error: e.message }, status: :unprocessable_content
  end

  rescue_from RefundError::PaymentAlreadyRefunded do |e|
    render json: { error: e.message }, status: :unprocessable_content
  end

  def index
    transaction = Payments::FindService.call(current_merchant, params[:payment_uid]).transaction
    result = Refunds::ListByPaymentService.call(transaction)

    render json: { refunds: result.refunds }, status: result.status
  end

  def create
    params.require([ :amount, :idempotency_key ])

    transaction = Payments::FindService.call(current_merchant, params[:payment_uid]).transaction
    result = Refunds::CreateService.call(transaction, refund_params)

    render json: result.refund, status: result.status
  end

  private
  def refund_params
    params.permit(:amount, :idempotency_key)
  end
end
