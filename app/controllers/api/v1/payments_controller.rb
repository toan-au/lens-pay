class Api::V1::PaymentsController < ApplicationController
  wrap_parameters false

  rescue_from PaymentError::InvalidCurrency do |e|
    render json: { error: e.message }, status: :bad_request
  end

  rescue_from PaymentError::ValidationFailed do |e|
    render json: { errors: e.messages }, status: :unprocessable_content
  end

  rescue_from PaymentError::NotFound do |e|
    render json: { error: e.message }, status: :not_found
  end

  rescue_from PaymentError::InvalidTransition do |e|
    render json: { error: e.message }, status: :unprocessable_content
  end

  rescue_from PaymentError::CapturedAmountExceedsAuthorized do |e|
    render json: { error: e.message }, status: :unprocessable_content
  end

  def create
    params.require([ :amount, :currency, :idempotency_key ])

    result = Payments::CreateService.call(transaction_params, current_merchant)

    render json: result.transaction, status: result.status
  end

  def show
    result = Payments::FindService.call(params[:uid])

    render json: result.transaction, status: result.status
  end

  def authorize
    result = Payments::AuthorizeService.call(find_transaction)

    render json: result.transaction, status: result.status
  end

  def capture
    result = Payments::CaptureService.call(find_transaction, captured_amount: params[:captured_amount]&.to_i)

    render json: result.transaction, status: result.status
  end

  def complete
    result = Payments::CompleteService.call(find_transaction)

    render json: result.transaction, status: result.status
  end

  def decline
    result = Payments::DeclineService.call(find_transaction)

    render json: result.transaction, status: result.status
  end

  private

  def find_transaction
    Payments::FindService.call(params[:uid]).transaction
  end

  def transaction_params
    params.permit(:amount, :currency, :idempotency_key)
  end
end
