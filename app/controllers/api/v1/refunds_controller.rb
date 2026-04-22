class Api::V1::RefundsController < ApplicationController
  def index
    result = Refunds::ListService.call(current_merchant, **list_params)

    render json: { refunds: result.refunds, next_cursor: result.next_cursor }, status: result.status
  end

  private

  def list_params
    params.permit(:cursor, :status, :limit).to_h.symbolize_keys
  end
end
