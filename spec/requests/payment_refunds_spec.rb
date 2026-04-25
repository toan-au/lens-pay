require 'rails_helper'

RSpec.describe "Refunds API", type: :request do
  let(:merchant) { create(:merchant) }
  let(:other_merchant) { create(:merchant) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{merchant.raw_api_key}" } }

  describe "POST /api/v1/payments/:payment_uid/refunds" do
    it "should respond with 401 when an invalid API key is provided" do
      payment = create(:transaction, captured_amount: 500, status: "succeeded")
      post "/api/v1/payments/#{payment.uid}/refunds", params: {
        amount: 500
      }, headers: { Authorization: "bad_api_key" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "creates a refund for a valid transaction" do
      payment = create(:transaction, captured_amount: 500, merchant:, status: "succeeded")
      post "/api/v1/payments/#{payment.uid}/refunds", params: {
        amount: 500,
        idempotency_key: "duck_duck_goose"
      }, headers: auth_headers

      expect(response).to have_http_status(201)
    end

    it "returns unprocessable_content for a fully refunded transaction" do
      payment = create(:transaction, captured_amount: 500, merchant:, status: "succeeded")
      create(:refund, payment: payment, amount: 500, status: "succeeded")

      post "/api/v1/payments/#{payment.uid}/refunds", params: {
        amount: 500,
        idempotency_key: "refund_already_refunded"
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns unprocessable_content for a refund that exceeds the refundable amount" do
      payment = create(:transaction, captured_amount: 500, merchant:, status: "succeeded")
      post "/api/v1/payments/#{payment.uid}/refunds", params: {
        amount: 5000,
        idempotency_key: "refund_exceeds_amount"
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /api/v1/payments/:payment_uid/refunds" do
    it "return's all of a transaction's refunds" do
      payment = create(:transaction, merchant:, amount: 1000, status: "succeeded")
      create(:refund, payment:, amount: 500)
      create(:refund, payment:, amount: 500)

      get "/api/v1/payments/#{payment.uid}/refunds", headers: auth_headers

      expect(response.parsed_body["refunds"].count).to eq(2)
      expect(response).to have_http_status(:ok)
    end

    it "returns an empty array if transaction has no refunds" do
      payment = create(:transaction, merchant:, amount: 900, status: "succeeded")
      get "/api/v1/payments/#{payment.uid}/refunds", headers: auth_headers

      expect(response.parsed_body["refunds"]).to eq([])
      expect(response).to have_http_status(:ok)
    end
  end

  describe "cross-merchant security" do
    it "returns 404 when refunding another merchant's payment" do
      other_payment = create(:transaction, :succeeded, captured_amount: 500, merchant: other_merchant)

      post "/api/v1/payments/#{other_payment.uid}/refunds", params: { amount: 500, idempotency_key: "refund_cross_merchant" }, headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when retrieving another merchant's refunds" do
      other_payment = create(:transaction, :succeeded, captured_amount: 500, merchant: other_merchant)

      get "/api/v1/payments/#{other_payment.uid}/refunds", headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
