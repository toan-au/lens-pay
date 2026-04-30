class Api::V1::PaymentsController < ApplicationController
  wrap_parameters false

  rescue_from PaymentError::InvalidCurrency do |e|
    render json: { error: e.message }, status: :bad_request
  end

  rescue_from PaymentError::ValidationFailed do |e|
    render json: { errors: e.messages }, status: :unprocessable_content
  end

  rescue_from PaymentError::InvalidTransition do |e|
    render json: { error: e.message }, status: :unprocessable_content
  end

  rescue_from PaymentError::CapturedAmountExceedsAuthorized do |e|
    render json: { error: e.message }, status: :unprocessable_content
  end

  def index
    result = Payments::ListService.call(
      current_merchant,
      cursor: list_params[:cursor],
      status: list_params[:status],
      limit: list_params[:limit]&.to_i
    )

    render json: {
      payments: result.transactions,
      next_cursor: result.next_cursor
    }, status: result.status
  end

  def create
    params.require([ :amount, :currency, :idempotency_key ])
    result = Payments::CreateService.call(current_merchant, create_payment_params)
    render json: result.transaction, status: result.status
  end

  def show
    result = Payments::FindService.call(current_merchant, params[:uid])
    render json: result.transaction, status: result.status
  end

  def capture
    result = Payments::CaptureService.call(find_payment, captured_amount: params[:captured_amount]&.to_i)
    render json: result.transaction, status: result.status
  end

  private

  def find_payment
    Payments::FindService.call(current_merchant, params[:uid]).transaction
  end

  def create_payment_params
    params.permit(:amount, :currency, :idempotency_key, metadata: {})
  end

  def list_params
    params.permit(:cursor, :status, :limit)
  end
end
