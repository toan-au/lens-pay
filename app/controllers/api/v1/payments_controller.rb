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
      payments: result.transactions.map { |t|
        t.as_json.merge(dispute_status: t.disputes.find { |d| d.open? || d.merchant_responded? }&.status)
      },
      next_cursor: result.next_cursor
    }, status: result.status
  end

  def create
    params.require([ :amount, :currency, :idempotency_key ])
    result = Payments::CreateService.call(current_merchant, create_payment_params)
    render json: serialize(result.transaction), status: result.status
  end

  def show
    result = Payments::FindService.call(current_merchant, params[:uid])
    render json: serialize(result.transaction), status: result.status
  end

  def capture
    result = Payments::CaptureService.call(find_payment, captured_amount: params[:captured_amount]&.to_i)
    render json: serialize(result.transaction), status: result.status
  end

  def cancel
    result = Payments::CancelService.call(find_payment)
    render json: serialize(result.transaction), status: result.status
  end

  # Test helper: stands in for the network confirming a cash payment.
  def simulate_confirmation
    result = Payments::ConfirmService.call(find_payment)
    render json: serialize(result.transaction), status: result.status
  end

  private

  def serialize(transaction)
    dispute = transaction.disputes.open_or_responded.first
    transaction.as_json.merge(
      customer: transaction.customer_snapshot,
      dispute: dispute&.as_json(only: %i[uid status reason amount currency respond_by resolved_at])
    )
  end

  def find_payment
    Payments::FindService.call(current_merchant, params[:uid]).transaction
  end

  def create_payment_params
    params.permit(:amount, :currency, :idempotency_key, :customer_uid, :payment_method, metadata: {})
  end

  def list_params
    params.permit(:cursor, :status, :limit)
  end
end
