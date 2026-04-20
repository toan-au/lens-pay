require 'rails_helper'

RSpec.describe "Refunds API", type: :request do
  let(:merchant) { create(:merchant) }
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
        amount: 500
      }, headers: auth_headers

      expect(response).to have_http_status(201)
    end

    it "returns unprocessable_content for a fully refunded transaction" do
      payment = create(:transaction, captured_amount: 500, merchant:, status: "succeeded")
      create(:refund, payment: payment, amount: 500, status: "succeeded")

      post "/api/v1/payments/#{payment.uid}/refunds", params: {
        amount: 500
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "return sunprocessable_content for a refnd that exceeds the refundable amount" do
      payment = create(:transaction, captured_amount: 500, merchant:, status: "succeeded")
      post "/api/v1/payments/#{payment.uid}/refunds", params: {
        amount: 5000
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
