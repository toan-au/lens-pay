require 'rails_helper'

RSpec.describe "Payments API", type: :request do
  let(:merchant) { create(:merchant) }
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

  it "creates a transaction in the pending state" do
    post "/api/v1/payments", params: {
      amount: 1000,
      currency: "JPY",
      idempotency_key: "test_key_1"
    }, headers: auth_headers

    expect(Transaction.last.status).to eq("pending")
  end

  it "should respond with a Bad Request when amount is negative" do
    post "/api/v1/payments", params: {
      amount: -1000,
      currency: "JPY",
      idempotency_key: "test_key_1"
    }, headers: auth_headers

    expect(response).to have_http_status(:unprocessable_content)
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

  describe "POST /authorize" do
    it "authorizes a pending transaction" do
      transaction = create(:transaction, merchant: merchant)

      post "/api/v1/payments/#{transaction.uid}/authorize", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("authorized")
    end

    it "returns 422 when the transaction is not pending" do
      transaction = create(:transaction, :authorized, merchant: merchant)

      post "/api/v1/payments/#{transaction.uid}/authorize", headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /capture" do
    it "captures a full amount by default" do
      transaction = create(:transaction, :authorized, amount: 1000, merchant: merchant)

      post "/api/v1/payments/#{transaction.uid}/capture", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("processing")
      expect(response.parsed_body["captured_amount"]).to eq(1000)
    end

    it "captures a partial amount" do
      transaction = create(:transaction, :authorized, amount: 1000, merchant: merchant)

      post "/api/v1/payments/#{transaction.uid}/capture", params: { captured_amount: 600 }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["captured_amount"]).to eq(600)
    end

    it "returns 422 when captured_amount exceeds the authorized amount" do
      transaction = create(:transaction, :authorized, amount: 1000, merchant: merchant)

      post "/api/v1/payments/#{transaction.uid}/capture", params: { captured_amount: 2000 }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when the transaction is not authorized" do
      transaction = create(:transaction, merchant: merchant)

      post "/api/v1/payments/#{transaction.uid}/capture", headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /complete" do
    it "completes a processing transaction" do
      transaction = create(:transaction, :processing, merchant: merchant)

      post "/api/v1/payments/#{transaction.uid}/complete", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("succeeded")
    end

    it "returns 422 when the transaction is not processing" do
      transaction = create(:transaction, :authorized, merchant: merchant)

      post "/api/v1/payments/#{transaction.uid}/complete", headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /decline" do
    %w[pending authorized processing].each do |state|
      it "declines a #{state} transaction" do
        transaction = create(:transaction, state.to_sym, merchant: merchant)

        post "/api/v1/payments/#{transaction.uid}/decline", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["status"]).to eq("declined")
      end
    end

    it "returns 422 when the transaction is already succeeded" do
      transaction = create(:transaction, :succeeded, merchant: merchant)

      post "/api/v1/payments/#{transaction.uid}/decline", headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
