require 'rails_helper'

RSpec.describe "Disputes API", type: :request do
  let(:merchant)       { create(:merchant) }
  let(:other_merchant) { create(:merchant) }
  let(:auth_headers)   { { 'Authorization' => "Bearer #{merchant.raw_api_key}" } }

  describe "POST /api/v1/payments/:uid/disputes" do
    it "creates a dispute for a succeeded payment" do
      payment = create(:transaction, :succeeded, merchant: merchant, amount: 5000)

      post "/api/v1/payments/#{payment.uid}/disputes", params: {
        reason: "fraudulent",
        amount: 5000,
        currency: "JPY"
      }, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(Dispute.count).to eq(1)
    end

    it "returns dispute data in the response" do
      payment = create(:transaction, :succeeded, merchant: merchant, amount: 5000)

      post "/api/v1/payments/#{payment.uid}/disputes", params: {
        reason: "fraudulent",
        amount: 5000,
        currency: "JPY"
      }, headers: auth_headers

      body = response.parsed_body
      expect(body["uid"]).to start_with("dis_")
      expect(body["status"]).to eq("open")
      expect(body["reason"]).to eq("fraudulent")
      expect(body["amount"]).to eq(5000)
      expect(body["respond_by"]).to be_present
    end

    it "returns 404 when payment does not exist" do
      post "/api/v1/payments/tr_nonexistent/disputes", params: {
        reason: "fraudulent", amount: 5000, currency: "JPY"
      }, headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 when payment has not succeeded" do
      payment = create(:transaction, merchant: merchant)

      post "/api/v1/payments/#{payment.uid}/disputes", params: {
        reason: "fraudulent", amount: 1000, currency: "JPY"
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when amount exceeds payment amount" do
      payment = create(:transaction, :succeeded, merchant: merchant, amount: 5000)

      post "/api/v1/payments/#{payment.uid}/disputes", params: {
        reason: "fraudulent", amount: 99999, currency: "JPY"
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when currency does not match payment currency" do
      payment = create(:transaction, :succeeded, merchant: merchant, amount: 5000, currency: "JPY")

      post "/api/v1/payments/#{payment.uid}/disputes", params: {
        reason: "fraudulent", amount: 5000, currency: "USD"
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when reason is invalid" do
      payment = create(:transaction, :succeeded, merchant: merchant, amount: 5000)

      post "/api/v1/payments/#{payment.uid}/disputes", params: {
        reason: "not_a_reason", amount: 5000, currency: "JPY"
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when payment already has an open dispute" do
      payment = create(:transaction, :succeeded, merchant: merchant, amount: 5000)
      create(:dispute, payment: payment, merchant: merchant)

      post "/api/v1/payments/#{payment.uid}/disputes", params: {
        reason: "fraudulent", amount: 5000, currency: "JPY"
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 401 when no API key is provided" do
      payment = create(:transaction, :succeeded, merchant: merchant, amount: 5000)

      post "/api/v1/payments/#{payment.uid}/disputes", params: {
        reason: "fraudulent", amount: 5000, currency: "JPY"
      }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 for another merchant's payment" do
      other_payment = create(:transaction, :succeeded, merchant: other_merchant, amount: 5000)

      post "/api/v1/payments/#{other_payment.uid}/disputes", params: {
        reason: "fraudulent", amount: 5000, currency: "JPY"
      }, headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
