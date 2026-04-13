class Api::V1::PaymentsController < ApplicationController
  wrap_parameters false

  rescue_from PaymentError::InvalidCurrency do |e|
    render json: { error: e.message }, status: :bad_request
  end

  rescue_from PaymentError::ValidationFailed do |e|
    render json: { errors: e.messages }, status: :unprocessable_entity
  end

  rescue_from PaymentError::NotFound do |e|
    render json: { error: e.message }, status: :not_found
  end

  def create
    params.require([:amount, :currency, :idempotency_key])

    result = Payments::CreateService.call(transaction_params)

    render json: result.transaction, status: result.status
  end

  def show
    result = Payments::FindService.call(params[:idempotency_key])

    render json: result.transaction, status: result.status
  end

  def update
  end

  private

  def transaction_params
    params.permit(:amount, :currency, :idempotency_key)
  end
end
