require 'rails_helper'

RSpec.describe "Customers API", type: :request do
  let(:merchant) { create(:merchant) }
  let(:other_merchant) { create(:merchant) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{merchant.raw_api_key}" } }

  describe "POST /api/v1/customers" do
    it "creates a customer and returns 201" do
      post "/api/v1/customers", params: { name: "Jane Doe", email: "jane@example.com" }, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["uid"]).to start_with("cus_")
      expect(response.parsed_body["name"]).to eq("Jane Doe")
      expect(response.parsed_body["email"]).to eq("jane@example.com")
    end

    it "scopes the customer to the current merchant" do
      post "/api/v1/customers", params: { name: "Jane Doe", email: "jane@example.com" }, headers: auth_headers

      expect(Customer.last.merchant).to eq(merchant)
    end

    it "accepts optional metadata" do
      post "/api/v1/customers", params: { name: "Jane", email: "jane@example.com", metadata: { tier: "gold" } }, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["metadata"]).to eq({ "tier" => "gold" })
    end

    it "returns 422 when name is missing" do
      post "/api/v1/customers", params: { email: "jane@example.com" }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
    end

    it "returns 422 when email is malformed" do
      post "/api/v1/customers", params: { name: "Jane", email: "not-an-email" }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 401 without auth" do
      post "/api/v1/customers", params: { name: "Jane", email: "jane@example.com" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/customers" do
    it "returns 200 with the merchant's customers" do
      create_list(:customer, 3, merchant:)

      get "/api/v1/customers", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["customers"].count).to eq(3)
    end

    it "returns customers newest first" do
      first  = create(:customer, merchant:, email: "first@example.com")
      second = create(:customer, merchant:, email: "second@example.com")

      get "/api/v1/customers", headers: auth_headers

      uids = response.parsed_body["customers"].map { |c| c["uid"] }
      expect(uids).to eq([ second.uid, first.uid ])
    end

    it "excludes deleted customers" do
      active  = create(:customer, merchant:)
      deleted = create(:customer, merchant:, email: "deleted@example.com")
      deleted.delete!

      get "/api/v1/customers", headers: auth_headers

      uids = response.parsed_body["customers"].map { |c| c["uid"] }
      expect(uids).to include(active.uid)
      expect(uids).not_to include(deleted.uid)
    end

    it "does not include customers from other merchants" do
      create(:customer, merchant: other_merchant)
      own = create(:customer, merchant:)

      get "/api/v1/customers", headers: auth_headers

      uids = response.parsed_body["customers"].map { |c| c["uid"] }
      expect(uids).to eq([ own.uid ])
    end

    it "paginates with a cursor" do
      create_list(:customer, 30, merchant:)

      get "/api/v1/customers", headers: auth_headers

      expect(response.parsed_body["customers"].count).to eq(25)
      next_cursor = response.parsed_body["next_cursor"]
      expect(next_cursor).to start_with("cus_")

      get "/api/v1/customers?cursor=#{next_cursor}", headers: auth_headers

      expect(response.parsed_body["customers"].count).to eq(5)
      expect(response.parsed_body["next_cursor"]).to be_nil
    end

    it "respects a custom limit" do
      create_list(:customer, 10, merchant:)

      get "/api/v1/customers?limit=4", headers: auth_headers

      expect(response.parsed_body["customers"].count).to eq(4)
    end

    it "returns 401 without auth" do
      get "/api/v1/customers"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
