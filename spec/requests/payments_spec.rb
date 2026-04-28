require 'rails_helper'

RSpec.describe "Payments API", type: :request do
  let(:merchant) { create(:merchant) }
  let(:other_merchant) { create(:merchant) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{merchant.raw_api_key}" } }

  describe "POST /api/v1/payments" do
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

    it "enqueues an AuthorizePaymentJob when a payment is created" do
      expect {
        post "/api/v1/payments", params: {
          amount: 1000,
          currency: "JPY",
          idempotency_key: "test_key_1"
        }, headers: auth_headers
      }.to have_enqueued_job(AuthorizePaymentJob)
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

    it "should return the existing payment when the same idempotency key is used" do
      Transaction.create!(amount: 1000, currency: "JPY", idempotency_key: "test_key_1", merchant: merchant)

      post "/api/v1/payments", params: {
        amount: 1000,
        currency: "JPY",
        idempotency_key: "test_key_1"
      }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(Transaction.count).to eq(1)
    end
  end

  describe "GET /api/v1/payments/:payment_uid" do
    it "should respond with a Not Found when the payment does not exist" do
      get "/api/v1/payments/nonexistent_uid", headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end

    it "should return a payment by uid" do
      transaction = Transaction.create!(amount: 1000, currency: "JPY", idempotency_key: "test_key_1", merchant: merchant)

      get "/api/v1/payments/#{transaction.uid}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["idempotency_key"]).to eq("test_key_1")
      expect(response.parsed_body["amount"]).to eq(1000)
    end
  end

  describe "GET /api/v1/payments" do
    it "returns a list of the current merchant's payments" do
      create_list(:transaction, 10, merchant:)

      get "/api/v1/payments", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["payments"].count).to eq(10)
    end

    it "filters the list of payments by provided filter query" do
      Transaction.statuses.keys.each { |status|
        create_list(:transaction, 3, merchant:, status:)
      }

      filter_status = "pending"
      get "/api/v1/payments?status=#{filter_status}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["payments"].count).to eq(3)
      response.parsed_body["payments"].each { |payment|
        expect(payment["status"]).to eq(filter_status)
      }
    end

    it "limits the number of returned items by a provided filter" do
      create_list(:transaction, 10, merchant:)

      limit = 5
      get "/api/v1/payments?limit=#{limit}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["payments"].count).to eq(limit)
    end

    it "pagination with cursor works" do
      create_list(:transaction, 40, merchant:)

      get "/api/v1/payments", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["payments"].count).to eq(25)

      next_cursor = response.parsed_body["next_cursor"]
      expect(next_cursor).to start_with("tr_")

      get "/api/v1/payments?cursor=#{next_cursor}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["payments"].count).to eq(15)
    end
  end

  describe "POST /api/v1/payments/:uid/capture" do
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

  # =============== SECURITY ==================

  describe "cross-merchant security" do
    let(:other_transaction) { create(:transaction, merchant: other_merchant) }

    it "does not return another merchant's payments" do
      create_list(:transaction, 3, merchant: other_merchant)
      create_list(:transaction, 2, merchant:)

      get "/api/v1/payments", headers: auth_headers

      expect(response.parsed_body["payments"].count).to eq(2)
    end

    it "returns 404 when fetching another merchant's payment" do
      get "/api/v1/payments/#{other_transaction.uid}", headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when capturing another merchant's payment" do
      post "/api/v1/payments/#{other_transaction.uid}/capture", headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
