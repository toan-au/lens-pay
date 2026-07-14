class Api::V1::WebhooksController < ApplicationController
  rescue_from JSON::ParserError do
    render json: { error: "Malformed JSON body" }, status: :bad_request
  end

  def ping
    WebhookDeliveryJob.perform_later(current_merchant.id, "ping", "Merchant", current_merchant.id, request_id: Current.request_id)
    render json: {}, status: :ok
  end

  def index
    result = Webhooks::ListService.call(
      current_merchant,
      cursor: list_params[:cursor],
      limit: list_params[:limit]&.to_i
    )

    render json: { webhook_events: result.webhook_events, next_cursor: result.next_cursor }, status: result.status
  end

  def payment_events
    payment = current_merchant.transactions.find_by(uid: params[:uid])
    return render json: { error: "Payment not found" }, status: :not_found unless payment

    webhook_events = current_merchant.webhook_events
      .where("payload->'data'->>'id' = ? OR payload->'data'->>'transaction_uid' = ?", payment.uid, payment.uid)
      .order(created_at: :desc)

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
      external_id = request.headers["X-LensPay-Id"].presence

      # Delivery retries reuse the same X-LensPay-Id; storing the event again
      # would show duplicates in the dashboard. Replays are acknowledged with
      # the same 200 the original got (idempotent consumer).
      if external_id && merchant.webhook_events.exists?(external_id:)
        return render json: {}, status: :ok
      end

      begin
        merchant.webhook_events.create!(
          event_type: parsed_body["type"],
          payload: parsed_body,
          external_id: external_id
        )
      rescue ActiveRecord::RecordNotUnique
        # Concurrent retry beat us to the insert; same acknowledgement.
      end
      render json: {}, status: :ok
    else render json: { error: "Invalid signature" }, status: :unauthorized
    end
  end

  private

  def list_params
    params.permit(:cursor, :limit)
  end
end
