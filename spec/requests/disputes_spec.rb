require 'rails_helper'

RSpec.describe "Disputes API", type: :request do
  let(:merchant)       { create(:merchant) }
  let(:other_merchant) { create(:merchant) }
  let(:auth_headers)   { { 'Authorization' => "Bearer #{merchant.raw_api_key}" } }

  describe "GET /api/v1/disputes" do
    it "returns a list of the current merchant's disputes" do
      create_list(:dispute, 3, merchant: merchant)

      get "/api/v1/disputes", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["disputes"].count).to eq(3)
    end

    it "does not return another merchant's disputes" do
      create_list(:dispute, 4, merchant: other_merchant)
      create_list(:dispute, 2, merchant: merchant)

      get "/api/v1/disputes", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["disputes"].count).to eq(2)
    end

    it "filters by status" do
      create(:dispute, merchant: merchant)
      create(:dispute, :won, merchant: merchant)
      create(:dispute, :lost, merchant: merchant)

      get "/api/v1/disputes?status=open", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["disputes"].count).to eq(1)
      expect(response.parsed_body["disputes"].first["status"]).to eq("open")
    end

    it "limits the number of returned items" do
      create_list(:dispute, 10, merchant: merchant)

      get "/api/v1/disputes?limit=4", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["disputes"].count).to eq(4)
    end

    it "paginates with a cursor" do
      create_list(:dispute, 30, merchant: merchant)

      get "/api/v1/disputes", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["disputes"].count).to eq(25)

      next_cursor = response.parsed_body["next_cursor"]
      expect(next_cursor).to start_with("dis_")

      get "/api/v1/disputes?cursor=#{next_cursor}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["disputes"].count).to eq(5)
    end

    it "returns 401 when no API key is provided" do
      get "/api/v1/disputes"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/disputes/:uid" do
    it "returns a dispute by uid" do
      dispute = create(:dispute, merchant: merchant)

      get "/api/v1/disputes/#{dispute.uid}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["uid"]).to eq(dispute.uid)
      expect(response.parsed_body["status"]).to eq("open")
    end

    it "returns 404 when the dispute does not exist" do
      get "/api/v1/disputes/dis_nonexistent", headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for another merchant's dispute" do
      other_dispute = create(:dispute, merchant: other_merchant)

      get "/api/v1/disputes/#{other_dispute.uid}", headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 when no API key is provided" do
      dispute = create(:dispute, merchant: merchant)

      get "/api/v1/disputes/#{dispute.uid}"

      expect(response).to have_http_status(:unauthorized)
    end
  end

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
