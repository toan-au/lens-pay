require "rails_helper"

RSpec.describe "POST /api/v1/demo/sessions", type: :request do
  it "returns 201 with an api_key" do
    post "/api/v1/demo/sessions"

    expect(response).to have_http_status(:created)
    expect(json_body).to have_key("api_key")
    expect(json_body["api_key"]).to start_with("sk_")
  end

  it "creates a new demo merchant on each call" do
    expect {
      post "/api/v1/demo/sessions"
      post "/api/v1/demo/sessions"
    }.to change(Merchant, :count).by(2)
  end

  it "does not require an Authorization header" do
    post "/api/v1/demo/sessions"
    expect(response).not_to have_http_status(:unauthorized)
  end

  it "returns the merchant uid" do
    post "/api/v1/demo/sessions"
    expect(json_body).to have_key("merchant_uid")
  end

  def json_body
    JSON.parse(response.body)
  end
end
