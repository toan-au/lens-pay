class Api::V1::RefundsController < ApplicationController
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

  def create
    params.require([ :amount ])

    transaction = Payments::FindService.call(params[:payment_uid]).result
    result = Refunds::CreateService.call(refund_params, transaction)

    render json: result.refund, status: result.status
  end

  private
  def refund_params
    params.permit(:amount)
  end
end
