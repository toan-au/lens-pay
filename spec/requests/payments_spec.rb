require 'rails_helper'

RSpec.describe "Payments API", type: :request do
    it "should create a Transaction when inputs are valid" do
        post "/api/v1/payments", params: {
            amount: 1000,
            currency: "JPY",
            idempotency_key: "test_key_1"
        }

        expect(response).to have_http_status(:created)
        
        expect(Transaction.count).to eq(1)
        expect(Transaction.last.amount).to eq(1000)
    end

    it "should respond with a Bad Request when amount is negative" do
        post "/api/v1/payments", params: {
            amount: -1000,
            currency: "JPY",
            idempotency_key: "test_key_1"
        }

        expect(response).to have_http_status(:unprocessable_entity)
    end

    it "should respond with a Bad Request when either amount, currency, or idempotency_key is missing" do
        post "/api/v1/payments", params: {
            currency: "JPY",
            idempotency_key: "test_key_1"
        }

        expect(response).to have_http_status(:bad_request)
        expect(Transaction.count).to eq(0)
    end

    it "should respond with a Bad Request when currency code is not valid" do
        post "/api/v1/payments", params: {
            amount: 1000,
            currency: "ABC",
            idempotency_key: "test_key_1"
        }

        expect(response).to have_http_status(:bad_request)
        expect(Transaction.count).to eq(0)
    end
end