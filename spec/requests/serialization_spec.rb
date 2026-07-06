require "rails_helper"

# Public payloads identify resources by uid only. Internal integer PKs and
# FKs must never leak into API responses (README: "All public-facing
# endpoints use these UIDs rather than integer primary keys").
RSpec.describe "Response serialization", type: :request do
  INTERNAL_KEYS = %w[id merchant_id customer_id transaction_id].freeze

  let(:merchant) { create(:merchant) }
  let(:auth_headers) { { "Authorization" => "Bearer #{merchant.raw_api_key}" } }

  it "does not expose internal ids on payments" do
    payment = create(:transaction, :succeeded, merchant: merchant)

    get "/api/v1/payments/#{payment.uid}", headers: auth_headers

    body = JSON.parse(response.body)
    expect(body["uid"]).to eq(payment.uid)
    expect(body.keys).not_to include(*INTERNAL_KEYS)
  end

  it "does not expose internal ids on customers" do
    customer = create(:customer, merchant: merchant)

    get "/api/v1/customers/#{customer.uid}", headers: auth_headers

    body = JSON.parse(response.body)
    expect(body["uid"]).to eq(customer.uid)
    expect(body.keys).not_to include(*INTERNAL_KEYS)
  end

  it "does not expose internal ids on refunds" do
    payment = create(:transaction, :succeeded, merchant: merchant)
    create(:refund, payment: payment)

    get "/api/v1/refunds", headers: auth_headers

    refund = JSON.parse(response.body).fetch("refunds").first
    expect(refund["payment_uid"]).to eq(payment.uid)
    expect(refund.keys).not_to include(*INTERNAL_KEYS)
  end

  it "does not expose internal ids on disputes" do
    payment = create(:transaction, :succeeded, merchant: merchant)
    dispute = create(:dispute, payment: payment, merchant: merchant)

    get "/api/v1/disputes/#{dispute.uid}", headers: auth_headers

    body = JSON.parse(response.body)
    expect(body["uid"]).to eq(dispute.uid)
    expect(body.keys).not_to include(*INTERNAL_KEYS)
  end

  # WebhookEvent and DisputeResponse have no uid column; their integer id is
  # the public identifier (the dashboard keys rows on it). Foreign keys still
  # stay internal.
  it "does not expose the merchant FK on webhook events" do
    create(:webhook_event, merchant: merchant)

    get "/api/v1/webhooks", headers: auth_headers

    event = JSON.parse(response.body).fetch("webhook_events").first
    expect(event["id"]).to be_a(Integer)
    expect(event.keys).not_to include("merchant_id")
  end

  it "does not expose the dispute FK on dispute responses" do
    payment = create(:transaction, :succeeded, merchant: merchant)
    dispute = create(:dispute, payment: payment, merchant: merchant)

    patch "/api/v1/disputes/#{dispute.uid}/respond",
      params: { evidence: { receipt: "order_123" } },
      headers: auth_headers

    body = JSON.parse(response.body)
    expect(body["id"]).to be_a(Integer)
    expect(body.keys).not_to include("dispute_id")
  end
end
