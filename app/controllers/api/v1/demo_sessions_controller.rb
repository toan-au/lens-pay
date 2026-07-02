class Api::V1::DemoSessionsController < ApplicationController
  def create
    result = Demo::SetupService.call

    render json: {
      api_key: result.api_key,
      merchant_uid: result.merchant.uid
    }, status: :created
  end
end
