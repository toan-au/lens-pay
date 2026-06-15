class Api::V1::DisputesController < ApplicationController
  rescue_from DisputeError::NotFound do |e|
    render json: { error: e.message }, status: :not_found
  end

  rescue_from DisputeError::ValidationFailed do |e|
    render json: { errors: e.messages }, status: :unprocessable_content
  end

  rescue_from DisputeError::InvalidTransition,
              DisputeError::RespondByPassed do |e|
    render json: { error: e.message }, status: :unprocessable_content
  end

  def index
    result = Disputes::ListService.call(
      current_merchant,
      cursor: list_params[:cursor],
      status: list_params[:status],
      limit:  list_params[:limit]&.to_i
    )

    render json: { disputes: result.disputes, next_cursor: result.next_cursor }, status: result.status
  end

  def show
    dispute = Disputes::FindService.call(current_merchant, params[:uid]).dispute
    render json: dispute, status: :ok
  end

  def respond
    dispute = Disputes::FindService.call(current_merchant, params[:uid]).dispute
    result  = Disputes::RespondService.call(dispute, evidence_params)
    render json: result.dispute_response, status: result.status
  end

  private

  def list_params
    params.permit(:cursor, :status, :limit)
  end

  def evidence_params
    params.permit(evidence: {}).to_h.fetch("evidence", {})
  end
end
