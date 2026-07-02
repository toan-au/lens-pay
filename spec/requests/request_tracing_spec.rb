require 'rails_helper'

RSpec.describe "Request Tracing", type: :request do
  let(:merchant)    { create(:merchant) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{merchant.raw_api_key}" } }

  it "includes X-Request-ID on every response" do
    get "/api/v1/payments", headers: auth_headers

    expect(response.headers["X-Request-ID"]).to be_present
  end

  it "returns a valid UUID as the request ID" do
    get "/api/v1/payments", headers: auth_headers

    uuid_format = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/
    expect(response.headers["X-Request-ID"]).to match(uuid_format)
  end

  it "generates a unique ID for each request" do
    get "/api/v1/payments", headers: auth_headers
    first_id = response.headers["X-Request-ID"]

    get "/api/v1/payments", headers: auth_headers
    second_id = response.headers["X-Request-ID"]

    expect(first_id).not_to eq(second_id)
  end

  it "includes X-Request-ID on unauthenticated responses" do
    get "/api/v1/payments"

    expect(response.headers["X-Request-ID"]).to be_present
  end
end
