require 'rails_helper'

RSpec.describe Disputes::RespondService do
  describe ".call" do
    it "creates a response and transitions dispute to merchant_responded" do
      dispute = create(:dispute)
      evidence = { customer_comment: "confirmation" }

      result = described_class.call(dispute, evidence)

      expect(result.status).to eq(:ok)
      expect(dispute.reload.status).to eq("merchant_responded")
      expect(DisputeResponse.count).to eq(1)
      expect(DisputeResponse.last.evidence).to eq({ "customer_comment" => "confirmation" })
    end

    it "creates a new response record on subsequent submissions" do
      dispute = create(:dispute, :merchant_responded)
      create(:dispute_response, dispute: dispute)
      evidence = { tracking_number: "1Z999AA" }

      described_class.call(dispute, evidence)

      expect(DisputeResponse.count).to eq(2)
    end

    it "does not change status on subsequent submissions" do
      dispute = create(:dispute, :merchant_responded)
      evidence = { tracking_number: "1Z999AA" }

      described_class.call(dispute, evidence)

      expect(dispute.reload.status).to eq("merchant_responded")
    end

    it "enqueues a dispute.responded webhook on success" do
      payment = create(:transaction, :succeeded, amount: 5000)
      dispute = create(:dispute, payment: payment)
      evidence = { customer_comment: "confirmation" }

      expect {
        described_class.call(dispute, evidence)
      }.to have_enqueued_job(WebhookDeliveryJob).with(
        payment.merchant_id, "dispute.responded", "Dispute", anything, request_id: nil
      )
    end

    it "raises InvalidTransition if dispute is already won or lost" do
      dispute = create(:dispute, :won)
      evidence = { customer_comment: "too late" }

      expect { described_class.call(dispute, evidence) }.to raise_error(DisputeError::InvalidTransition)
    end

    it "raises RespondByPassed if respond_by has passed" do
      dispute = create(:dispute, respond_by: 1.day.ago)
      evidence = { customer_comment: "confirmation" }

      expect { described_class.call(dispute, evidence) }.to raise_error(DisputeError::RespondByPassed)
    end

    it "raises ValidationFailed if evidence is empty" do
      dispute = create(:dispute)

      expect { described_class.call(dispute, {}) }.to raise_error(DisputeError::ValidationFailed)
    end

    it "raises ValidationFailed if evidence is not a hash" do
      dispute = create(:dispute)

      expect { described_class.call(dispute, "not a hash") }.to raise_error(DisputeError::ValidationFailed)
    end
  end
end
