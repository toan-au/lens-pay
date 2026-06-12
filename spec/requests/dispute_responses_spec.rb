require 'rails_helper'

RSpec.describe "Dispute Responses API", type: :request do
  let(:merchant)       { create(:merchant) }
  let(:other_merchant) { create(:merchant) }
  let(:auth_headers)   { { 'Authorization' => "Bearer #{merchant.raw_api_key}" } }

  describe "PATCH /api/v1/disputes/:uid/respond" do
    it "creates a dispute response and transitions dispute to merchant_responded" do
      dispute = create(:dispute, merchant: merchant)

      patch "/api/v1/disputes/#{dispute.uid}/respond", params: {
        evidence: { tracking_number: "1Z999AA" }
      }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(DisputeResponse.count).to eq(1)
      expect(dispute.reload.status).to eq("merchant_responded")
    end

    it "allows subsequent responses on an already responded dispute" do
      dispute = create(:dispute, :merchant_responded, merchant: merchant)

      patch "/api/v1/disputes/#{dispute.uid}/respond", params: {
        evidence: { additional_proof: "more evidence" }
      }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(DisputeResponse.count).to eq(1)
    end

    it "returns 404 when dispute does not exist" do
      patch "/api/v1/disputes/dis_nonexistent/respond", params: {
        evidence: { tracking_number: "1Z999AA" }
      }, headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 when dispute is already won or lost" do
      dispute = create(:dispute, :won, merchant: merchant)

      patch "/api/v1/disputes/#{dispute.uid}/respond", params: {
        evidence: { tracking_number: "1Z999AA" }
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when respond_by deadline has passed" do
      dispute = create(:dispute, merchant: merchant, respond_by: 1.day.ago)

      patch "/api/v1/disputes/#{dispute.uid}/respond", params: {
        evidence: { tracking_number: "1Z999AA" }
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when evidence is empty" do
      dispute = create(:dispute, merchant: merchant)

      patch "/api/v1/disputes/#{dispute.uid}/respond", params: {
        evidence: {}
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 401 when no API key is provided" do
      dispute = create(:dispute, merchant: merchant)

      patch "/api/v1/disputes/#{dispute.uid}/respond", params: {
        evidence: { tracking_number: "1Z999AA" }
      }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 for another merchant's dispute" do
      other_dispute = create(:dispute, merchant: other_merchant)

      patch "/api/v1/disputes/#{other_dispute.uid}/respond", params: {
        evidence: { tracking_number: "1Z999AA" }
      }, headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
