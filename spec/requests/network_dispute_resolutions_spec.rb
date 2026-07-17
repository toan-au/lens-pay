require 'rails_helper'

RSpec.describe "Network Dispute Resolutions API", type: :request do
  let(:network_headers) { { 'X-Network-Secret' => 'test-network-secret' } }

  around do |example|
    ClimateControl.modify(NETWORK_SECRET: 'test-network-secret') { example.run }
  end

  describe "POST /api/v1/webhooks/network/disputes/resolve" do
    it "resolves an open dispute as won" do
      dispute = create(:dispute)

      post "/api/v1/webhooks/network/disputes/resolve",
           params: { case_reference: dispute.provider_reference, outcome: "won" },
           headers: network_headers

      expect(response).to have_http_status(:ok)
      expect(dispute.reload.status).to eq("won")
      expect(dispute.reload.resolved_at).to be_present
    end

    it "resolves an open dispute as lost" do
      dispute = create(:dispute)

      post "/api/v1/webhooks/network/disputes/resolve",
           params: { case_reference: dispute.provider_reference, outcome: "lost" },
           headers: network_headers

      expect(response).to have_http_status(:ok)
      expect(dispute.reload.status).to eq("lost")
    end

    it "resolves a merchant_responded dispute" do
      dispute = create(:dispute, :merchant_responded)

      post "/api/v1/webhooks/network/disputes/resolve",
           params: { case_reference: dispute.provider_reference, outcome: "won" },
           headers: network_headers

      expect(response).to have_http_status(:ok)
      expect(dispute.reload.status).to eq("won")
    end

    it "returns 401 when the network secret is missing" do
      dispute = create(:dispute)

      post "/api/v1/webhooks/network/disputes/resolve",
           params: { case_reference: dispute.provider_reference, outcome: "won" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when the network secret is wrong" do
      dispute = create(:dispute)

      post "/api/v1/webhooks/network/disputes/resolve",
           params: { case_reference: dispute.provider_reference, outcome: "won" },
           headers: { 'X-Network-Secret' => 'wrong-secret' }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 when no dispute matches the case reference" do
      post "/api/v1/webhooks/network/disputes/resolve",
           params: { case_reference: "CASE-NOPE", outcome: "won" },
           headers: network_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 when the outcome is invalid" do
      dispute = create(:dispute)

      post "/api/v1/webhooks/network/disputes/resolve",
           params: { case_reference: dispute.provider_reference, outcome: "invalid" },
           headers: network_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when the dispute is already resolved" do
      dispute = create(:dispute, :won)

      post "/api/v1/webhooks/network/disputes/resolve",
           params: { case_reference: dispute.provider_reference, outcome: "lost" },
           headers: network_headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
