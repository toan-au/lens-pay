require 'rails_helper'

RSpec.describe "Refunds API", type: :request do
  let(:merchant) { create(:merchant) }
  let(:other_merchant) { create(:merchant) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{merchant.raw_api_key}" } }

  describe "GET /api/v1/refunds" do
    it "returns all refunds for the current merchant" do
      payment = create(:transaction, :succeeded, captured_amount: 1000, merchant:)
      create(:refund, payment:, amount: 500)
      create(:refund, payment:, amount: 250)

      get "/api/v1/refunds", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["refunds"].count).to eq(2)
    end

    it "includes payment_uid and currency on each refund" do
      payment = create(:transaction, :succeeded, captured_amount: 1000, merchant:, currency: "JPY")
      create(:refund, payment:, amount: 500)

      get "/api/v1/refunds", headers: auth_headers

      refund = response.parsed_body["refunds"].first
      expect(refund["payment_uid"]).to eq(payment.uid)
      expect(refund["currency"]).to eq("JPY")
    end

    it "returns an empty array when the merchant has no refunds" do
      get "/api/v1/refunds", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["refunds"]).to eq([])
    end

    it "filters by status" do
      payment = create(:transaction, :succeeded, captured_amount: 1000, merchant:)
      create(:refund, payment:, amount: 500, status: "succeeded")
      create(:refund, payment:, amount: 250, status: "pending")

      get "/api/v1/refunds?status=succeeded", headers: auth_headers

      expect(response.parsed_body["refunds"].count).to eq(1)
      expect(response.parsed_body["refunds"].first["status"]).to eq("succeeded")
    end

    it "returns 401 when unauthorized" do
      get "/api/v1/refunds"

      expect(response).to have_http_status(:unauthorized)
    end

    describe "cross-merchant security" do
      it "does not return another merchant's refunds" do
        own_payment = create(:transaction, :succeeded, captured_amount: 1000, merchant:)
        other_payment = create(:transaction, :succeeded, captured_amount: 1000, merchant: other_merchant)
        create(:refund, payment: own_payment, amount: 500)
        create(:refund, payment: other_payment, amount: 500)

        get "/api/v1/refunds", headers: auth_headers

        expect(response.parsed_body["refunds"].count).to eq(1)
      end
    end
  end
end
