class Api::V1::CustomersController < ApplicationController
  wrap_parameters false

  rescue_from CustomerError::ValidationFailed do |e|
    render json: { errors: e.messages }, status: :unprocessable_content
  end

  def index
    result = Customers::ListService.call(
      current_merchant,
      cursor: list_params[:cursor],
      limit: list_params[:limit]&.to_i
    )

    render json: { customers: result.customers, next_cursor: result.next_cursor }, status: result.status
  end

  def create
    result = Customers::CreateService.call(current_merchant, create_params)
    render json: result.customer, status: result.status
  end

  private

  def create_params
    params.permit(:name, :email, metadata: {})
  end

  def list_params
    params.permit(:cursor, :limit)
  end
end
