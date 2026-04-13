require 'rails_helper'

RSpec.describe "Payments API", type: :request do
  let(:merchant) { Merchant.create!(name: "Test Merchant") }
  let(:auth_headers) { { 'Authorization' => "Bearer #{merchant.raw_api_key}" } }

  it "should create a Transaction when inputs are valid" do
    post "/api/v1/payments", params: {
      amount: 1000,
      currency: "JPY",
      idempotency_key: "test_key_1"
    }, headers: auth_headers

    expect(response).to have_http_status(:created)
    expect(Transaction.count).to eq(1)
    expect(Transaction.last.amount).to eq(1000)
  end

  it "should respond with a Bad Request when amount is negative" do
    post "/api/v1/payments", params: {
      amount: -1000,
      currency: "JPY",
      idempotency_key: "test_key_1"
    }, headers: auth_headers

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "should respond with a Bad Request when either amount, currency, or idempotency_key is missing" do
    post "/api/v1/payments", params: {
      currency: "JPY",
      idempotency_key: "test_key_1"
    }, headers: auth_headers

    expect(response).to have_http_status(:bad_request)
    expect(Transaction.count).to eq(0)
  end

  it "should respond with a Bad Request when currency code is not valid" do
    post "/api/v1/payments", params: {
      amount: 1000,
      currency: "ABC",
      idempotency_key: "test_key_1"
    }, headers: auth_headers

    expect(response).to have_http_status(:bad_request)
    expect(Transaction.count).to eq(0)
  end

  it "should respond with 401 when no API key is provided" do
    post "/api/v1/payments", params: {
      amount: 1000,
      currency: "JPY",
      idempotency_key: "test_key_1"
    }

    expect(response).to have_http_status(:unauthorized)
  end

  it "should respond with 401 when an invalid API key is provided" do
    post "/api/v1/payments", params: {
      amount: 1000,
      currency: "JPY",
      idempotency_key: "test_key_1"
    }, headers: { 'Authorization' => 'Bearer sk_invalid' }

    expect(response).to have_http_status(:unauthorized)
  end

  it "should respond with a Not Found when the payment does not exist" do
    get "/api/v1/payments/nonexistent_uid", headers: auth_headers

    expect(response).to have_http_status(:not_found)
  end

  it "should return the existing transaction when the same idempotency key is used" do
    Transaction.create!(amount: 1000, currency: "JPY", idempotency_key: "test_key_1", merchant: merchant)

    post "/api/v1/payments", params: {
      amount: 1000,
      currency: "JPY",
      idempotency_key: "test_key_1"
    }, headers: auth_headers

    expect(response).to have_http_status(:ok)
    expect(Transaction.count).to eq(1)
  end

  it "should return a transaction by uid" do
    transaction = Transaction.create!(amount: 1000, currency: "JPY", idempotency_key: "test_key_1", merchant: merchant)

    get "/api/v1/payments/#{transaction.uid}", headers: auth_headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["idempotency_key"]).to eq("test_key_1")
    expect(response.parsed_body["amount"]).to eq(1000)
  end
end
