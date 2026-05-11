require 'rails_helper'

RSpec.describe "Webhooks API", type: :request do
  let(:merchant) { create(:merchant) }
  let(:auth_headers) { { "Authorization" => "Bearer #{merchant.raw_api_key}" } }

  describe "POST /api/v1/webhooks/ping" do
    it "enqueues a ping webhook delivery and returns 200" do
      expect {
        post "/api/v1/webhooks/ping", headers: auth_headers
      }.to have_enqueued_job(WebhookDeliveryJob).with(merchant.id, "ping", "Merchant", merchant.id)

      expect(response).to have_http_status(:ok)
    end

    it "returns 401 without auth" do
      post "/api/v1/webhooks/ping"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/webhooks" do
    it "returns events for the authenticated merchant, newest first" do
      older = create(:webhook_event, merchant: merchant, event_type: "payment.authorized", created_at: 2.minutes.ago)
      newer = create(:webhook_event, merchant: merchant, event_type: "payment.succeeded", created_at: 1.minute.ago)

      get "/api/v1/webhooks", headers: auth_headers

      expect(response).to have_http_status(:ok)
      types = response.parsed_body["webhook_events"].map { |e| e["event_type"] }
      expect(types).to eq([ newer.event_type, older.event_type ])
    end

    it "does not return events belonging to another merchant" do
      create(:webhook_event, merchant: create(:merchant))

      get "/api/v1/webhooks", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["webhook_events"]).to be_empty
    end

    it "returns 401 without auth" do
      get "/api/v1/webhooks"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/webhooks/:merchant_uid" do
    let(:payload) { { id: "evt_123", type: "payment.succeeded", data: {} }.to_json }
    let(:signature) do
      "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", merchant.webhook_secret, payload)
    end
    let(:valid_headers) { { "Content-Type" => "application/json", "X-LensPay-Signature" => signature } }

    context "with a valid signature" do
      it "stores the event and returns 200" do
        post "/api/v1/webhooks/#{merchant.uid}", params: payload, headers: valid_headers

        expect(response).to have_http_status(:ok)
        expect(WebhookEvent.count).to eq(1)
      end

      it "stores the correct event_type" do
        post "/api/v1/webhooks/#{merchant.uid}", params: payload, headers: valid_headers

        expect(WebhookEvent.last.event_type).to eq("payment.succeeded")
      end
    end

    context "with an invalid signature" do
      it "returns 401" do
        post "/api/v1/webhooks/#{merchant.uid}", params: payload,
          headers: valid_headers.merge("X-LensPay-Signature" => "sha256=badsignature")

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with an unknown merchant UID" do
      it "returns 404" do
        post "/api/v1/webhooks/mch_unknown", params: payload, headers: valid_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
