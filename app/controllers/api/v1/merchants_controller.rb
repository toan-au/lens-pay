class Api::V1::MerchantsController < ApplicationController
  wrap_parameters false

  rescue_from MerchantError::ValidationFailed do |e|
    render json: { errors: e.messages }, status: :unprocessable_content
  end

  rescue_from MerchantError::NotFound do |e|
    render json: { error: e.message }, status: :not_found
  end

  def create
    params.require([ :name, :email, :country, :currency ])

    result = Merchants::CreateService.call(merchant_params)

    render json: { uid: result.merchant.uid, api_key: result.merchant.raw_api_key }, status: result.status
  end

  def show
    raise MerchantError::NotFound unless params[:uid] == current_merchant.uid

    render json: current_merchant.as_json(only: %i[uid name email country currency status webhook_url]),
           status: :ok
  end

  private

  def merchant_params
    params.permit(:name, :email, :country, :currency, :webhook_url)
  end
end
