class Api::V1::RefundsController < ApplicationController
  def index
    result = Refunds::ListService.call(current_merchant, **list_params)

    refunds = result.refunds.map { |r| r.as_json.merge(payment_uid: r.payment.uid, currency: r.payment.currency) }
    render json: { refunds:, next_cursor: result.next_cursor }, status: result.status
  end

  private

  def list_params
    params.permit(:cursor, :status, :limit).to_h.symbolize_keys
  end
end
