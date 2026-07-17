require 'rails_helper'

RSpec.describe "Network Payment Confirmations API", type: :request do
  let(:network_headers) { { 'X-Network-Secret' => 'test-network-secret' } }

  around do |example|
    ClimateControl.modify(NETWORK_SECRET: 'test-network-secret') { example.run }
  end

  describe "POST /api/v1/webhooks/network/payments/confirm" do
    it "moves a pending konbini payment to processing and enqueues settlement" do
      payment = create(:transaction, :konbini)

      post "/api/v1/webhooks/network/payments/confirm",
        params: { reference: payment.provider_reference }, headers: network_headers

      expect(response).to have_http_status(:ok)
      payment.reload
      expect(payment.status).to eq("processing")
      expect(payment.captured_amount).to eq(payment.amount)
      expect(SettlePaymentJob).to have_been_enqueued
    end

    it "confirms a pending bank transfer payment" do
      payment = create(:transaction, :bank_transfer)

      post "/api/v1/webhooks/network/payments/confirm",
        params: { reference: payment.provider_reference }, headers: network_headers

      expect(response).to have_http_status(:ok)
      expect(payment.reload.status).to eq("processing")
    end

    it "enqueues a payment.confirmed webhook" do
      payment = create(:transaction, :konbini)

      post "/api/v1/webhooks/network/payments/confirm",
        params: { reference: payment.provider_reference }, headers: network_headers

      expect(WebhookDeliveryJob).to have_been_enqueued.with(
        payment.merchant_id, "payment.confirmed", "Transaction", payment.id, request_id: anything
      )
    end

    it "rejects confirmation of a card payment" do
      payment = create(:transaction, payment_method: :card)

      post "/api/v1/webhooks/network/payments/confirm",
        params: { reference: payment.provider_reference }, headers: network_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(payment.reload.status).to eq("pending")
    end

    it "rejects confirmation of an already-expired payment" do
      payment = create(:transaction, :konbini, status: :expired)

      post "/api/v1/webhooks/network/payments/confirm",
        params: { reference: payment.provider_reference }, headers: network_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 404 for an unknown reference" do
      post "/api/v1/webhooks/network/payments/confirm",
        params: { reference: "KNB-NOPE" }, headers: network_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 400 without a reference" do
      post "/api/v1/webhooks/network/payments/confirm", params: {}, headers: network_headers

      expect(response).to have_http_status(:bad_request)
    end

    it "returns 401 with a wrong network secret" do
      payment = create(:transaction, :konbini)

      post "/api/v1/webhooks/network/payments/confirm",
        params: { reference: payment.provider_reference },
        headers: { 'X-Network-Secret' => 'wrong' }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
