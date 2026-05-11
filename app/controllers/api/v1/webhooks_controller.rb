class Api::V1::WebhooksController < ApplicationController
  def ping
    WebhookDeliveryJob.perform_later(current_merchant.id, "ping", "Merchant", current_merchant.id)
    render json: {}, status: :ok
  end

  def index
    webhook_events = current_merchant.webhook_events.order(created_at: :desc)
    render json: { webhook_events: }, status: :ok
  end

  def create
    merchant_uid = params[:merchant_uid]
    merchant = Merchant.find_by(uid: merchant_uid)

    return render json: { error: "Not found" }, status: :not_found unless merchant

    body = request.body.read
    parsed_body = JSON.parse(body)

    signature = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", merchant.webhook_secret, body)

    return render json: { error: "Invalid signature" }, status: :unauthorized unless request.headers["X-LensPay-Signature"]

    if ActiveSupport::SecurityUtils.secure_compare(request.headers["X-LensPay-Signature"], signature)
      merchant.webhook_events.create!(
        event_type: parsed_body["type"],
        payload: parsed_body
      )
      render json: {}, status: :ok
    else render json: { error: "Invalid signature" }, status: :unauthorized
    end
  end
end
