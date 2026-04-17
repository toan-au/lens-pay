class ApplicationController < ActionController::API
  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: "Missing parameter: #{e.param}" }, status: :bad_request
  end

  rescue_from PaymentError::NotFound do |e|
    render json: { error: e.message }, status: :not_found
  end

  def current_merchant
    request.env["current_merchant"]
  end
end
