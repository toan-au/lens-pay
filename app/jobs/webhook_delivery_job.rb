require "net/http"
require "openssl"

class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks

  retry_on WebhookError::DeliveryFailed, wait: ->(executions) { executions == 1 ? 30.seconds : 5.minutes }, attempts: 3 do |job, error|
    merchant_id, event_type, resource_class, resource_id = job.arguments
    merchant  = Merchant.find(merchant_id)
    resource  = resource_class.constantize.find(resource_id)
    AuditLogger.log(
      event: "webhook.delivered",
      status: "failed",
      error: error,
      merchant_uid: merchant.uid,
      event_type: event_type,
      webhook_url: merchant.webhook_url,
      resource_uid: resource.uid
    )
  end

  def perform(merchant_id, event_type, resource_class, resource_id)
    merchant = Merchant.find(merchant_id)
    return unless merchant.webhook_url.present?

    resource = resource_class.constantize.find(resource_id)
    event_id = "evt_#{job_id}"
    body = Webhooks::BuildPayloadService.call(event_type:, resource:, event_id:)

    deliver(merchant, event_type, event_id, body)

    AuditLogger.log(
      event: "webhook.delivered",
      status: "succeeded",
      merchant_uid: merchant.uid,
      event_type: event_type,
      webhook_url: merchant.webhook_url,
      resource_uid: resource.uid
    )
  end

  private

  def deliver(merchant, event_type, event_id, body)
    uri = URI(merchant.webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 10

    signature = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", merchant.webhook_secret, body)

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["User-Agent"] = "LensPay-Webhook"
    request["X-LensPay-Event"] = event_type
    request["X-LensPay-Id"] = event_id
    request["X-LensPay-Signature"] = signature
    request.body = body

    response = http.request(request)
    raise WebhookError::DeliveryFailed.new("HTTP #{response.code}") unless response.is_a?(Net::HTTPSuccess)
  rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
    raise WebhookError::DeliveryFailed.new(e.message)
  end
end
