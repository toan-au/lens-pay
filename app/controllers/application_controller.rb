class ApplicationController < ActionController::API
  before_action { Current.request_id = request.request_id }

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: "Missing parameter: #{e.param}" }, status: :bad_request
  end

  rescue_from PaymentError::NotFound, CustomerError::NotFound do |e|
    render json: { error: e.message }, status: :not_found
  end

  def current_merchant
    request.env["current_merchant"]
  end

  def append_info_to_payload(payload)
    super
    payload[:merchant_uid] = current_merchant&.uid
  end
end
