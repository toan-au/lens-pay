require 'rails_helper'

RSpec.describe "Merchants API", type: :request do
  describe "POST /api/v1/merchants" do
    let(:valid_params) do
      { name: "Acme Corp", email: "acme@example.com", country: "JP", currency: "JPY" }
    end

    it "creates a merchant and returns the uid and api key" do
      post "/api/v1/merchants", params: valid_params

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["uid"]).to start_with("mch_")
      expect(response.parsed_body["api_key"]).to start_with("sk_")
    end

    it "returns the webhook_secret on creation" do
      post "/api/v1/merchants", params: valid_params

      expect(response.parsed_body["webhook_secret"]).to start_with("whs_")
    end

    it "does not expose the api_key_digest in the response" do
      post "/api/v1/merchants", params: valid_params

      expect(response.parsed_body).not_to have_key("api_key_digest")
    end

    it "returns bad request when required fields are missing" do
      post "/api/v1/merchants", params: { name: "Acme Corp" }

      expect(response).to have_http_status(:bad_request)
    end

    it "returns unprocessable entity when currency is invalid" do
      post "/api/v1/merchants", params: valid_params.merge(currency: "XYZ")

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns unprocessable entity when country code is not 2 characters" do
      post "/api/v1/merchants", params: valid_params.merge(country: "JPN")

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /api/v1/merchants/me" do
    let(:merchant) { create(:merchant) }
    let(:auth_headers) { { "Authorization" => "Bearer #{merchant.raw_api_key}" } }

    it "returns the merchant profile" do
      get "/api/v1/merchants/me", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["uid"]).to eq(merchant.uid)
      expect(response.parsed_body["webhook_secret"]).to eq(merchant.webhook_secret)
    end

    it "returns 401 without auth" do
      get "/api/v1/merchants/me"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/merchants/me" do
    let(:merchant) { create(:merchant) }
    let(:auth_headers) { { "Authorization" => "Bearer #{merchant.raw_api_key}" } }

    it "updates the webhook_url" do
      patch "/api/v1/merchants/me", params: { webhook_url: "https://example.com/webhooks" }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["webhook_url"]).to eq("https://example.com/webhooks")
    end

    it "returns unprocessable entity for an invalid webhook_url" do
      patch "/api/v1/merchants/me", params: { webhook_url: "not-a-url" }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 401 without auth" do
      patch "/api/v1/merchants/me", params: { webhook_url: "https://example.com/webhooks" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
