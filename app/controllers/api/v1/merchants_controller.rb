class Api::V1::MerchantsController < ApplicationController
  wrap_parameters false

  rescue_from MerchantError::ValidationFailed do |e|
    render json: { errors: e.messages }, status: :unprocessable_content
  end

  def create
    params.require([ :name, :email, :country, :currency ])

    result = Merchants::CreateService.call(merchant_params)

    render json: {
      uid: result.merchant.uid,
      api_key: result.merchant.raw_api_key,
      webhook_secret: result.merchant.webhook_secret
    }, status: result.status
  end

  def me
    render json: current_merchant.as_json(only: %i[uid name email country currency status webhook_url webhook_secret]),
           status: :ok
  end

  def update
    if current_merchant.update(update_params)
      render json: current_merchant.as_json(only: %i[uid name email country currency status webhook_url webhook_secret]),
             status: :ok
    else
      raise MerchantError::ValidationFailed.new(current_merchant.errors.full_messages)
    end
  end

  private

  def merchant_params
    params.permit(:name, :email, :country, :currency, :webhook_url)
  end

  def update_params
    params.permit(:webhook_url)
  end
end
