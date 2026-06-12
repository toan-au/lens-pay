require 'rails_helper'

RSpec.describe "Network Disputes API", type: :request do
  let(:network_headers) { { 'X-Network-Secret' => 'test-network-secret' } }

  around do |example|
    ClimateControl.modify(NETWORK_SECRET: 'test-network-secret') { example.run }
  end

  describe "POST /api/v1/webhooks/network/disputes" do
    it "creates a dispute for a succeeded payment" do
      payment = create(:transaction, :succeeded, amount: 5000, currency: "JPY")

      post "/api/v1/webhooks/network/disputes", params: {
        payment_uid: payment.uid,
        reason: "fraudulent",
        amount: 5000,
        currency: "JPY"
      }, headers: network_headers

      expect(response).to have_http_status(:created)
      expect(Dispute.count).to eq(1)
    end

    it "returns dispute data in the response" do
      payment = create(:transaction, :succeeded, amount: 5000, currency: "JPY")

      post "/api/v1/webhooks/network/disputes", params: {
        payment_uid: payment.uid,
        reason: "fraudulent",
        amount: 5000,
        currency: "JPY"
      }, headers: network_headers

      body = response.parsed_body
      expect(body["uid"]).to start_with("dis_")
      expect(body["status"]).to eq("open")
      expect(body["reason"]).to eq("fraudulent")
      expect(body["amount"]).to eq(5000)
      expect(body["respond_by"]).to be_present
    end

    it "returns 401 when the network secret is missing" do
      payment = create(:transaction, :succeeded, amount: 5000, currency: "JPY")

      post "/api/v1/webhooks/network/disputes", params: {
        payment_uid: payment.uid,
        reason: "fraudulent",
        amount: 5000,
        currency: "JPY"
      }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when the network secret is wrong" do
      payment = create(:transaction, :succeeded, amount: 5000, currency: "JPY")

      post "/api/v1/webhooks/network/disputes", params: {
        payment_uid: payment.uid,
        reason: "fraudulent",
        amount: 5000,
        currency: "JPY"
      }, headers: { 'X-Network-Secret' => 'wrong-secret' }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 when the payment does not exist" do
      post "/api/v1/webhooks/network/disputes", params: {
        payment_uid: "tr_nonexistent",
        reason: "fraudulent",
        amount: 5000,
        currency: "JPY"
      }, headers: network_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 when the payment has not succeeded" do
      payment = create(:transaction)

      post "/api/v1/webhooks/network/disputes", params: {
        payment_uid: payment.uid,
        reason: "fraudulent",
        amount: 1000,
        currency: "JPY"
      }, headers: network_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when the amount exceeds the payment amount" do
      payment = create(:transaction, :succeeded, amount: 5000, currency: "JPY")

      post "/api/v1/webhooks/network/disputes", params: {
        payment_uid: payment.uid,
        reason: "fraudulent",
        amount: 99999,
        currency: "JPY"
      }, headers: network_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when the currency does not match the payment" do
      payment = create(:transaction, :succeeded, amount: 5000, currency: "JPY")

      post "/api/v1/webhooks/network/disputes", params: {
        payment_uid: payment.uid,
        reason: "fraudulent",
        amount: 5000,
        currency: "USD"
      }, headers: network_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when the reason is invalid" do
      payment = create(:transaction, :succeeded, amount: 5000, currency: "JPY")

      post "/api/v1/webhooks/network/disputes", params: {
        payment_uid: payment.uid,
        reason: "not_a_reason",
        amount: 5000,
        currency: "JPY"
      }, headers: network_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when the payment already has an open dispute" do
      payment = create(:transaction, :succeeded, amount: 5000, currency: "JPY")
      create(:dispute, payment: payment, merchant: payment.merchant)

      post "/api/v1/webhooks/network/disputes", params: {
        payment_uid: payment.uid,
        reason: "fraudulent",
        amount: 5000,
        currency: "JPY"
      }, headers: network_headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
