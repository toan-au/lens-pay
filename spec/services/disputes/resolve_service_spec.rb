require 'rails_helper'

RSpec.describe Disputes::ResolveService do
  describe ".call" do
    it "transitions an open dispute to won" do
      dispute = create(:dispute)

      result = described_class.call(dispute, "won")

      expect(result.status).to eq(:ok)
      expect(dispute.reload.status).to eq("won")
    end

    it "transitions an open dispute to lost" do
      dispute = create(:dispute)

      result = described_class.call(dispute, "lost")

      expect(result.status).to eq(:ok)
      expect(dispute.reload.status).to eq("lost")
    end

    it "transitions a merchant_responded dispute to won" do
      dispute = create(:dispute, :merchant_responded)

      result = described_class.call(dispute, "won")

      expect(dispute.reload.status).to eq("won")
    end

    it "transitions a merchant_responded dispute to lost" do
      dispute = create(:dispute, :merchant_responded)

      result = described_class.call(dispute, "lost")

      expect(dispute.reload.status).to eq("lost")
    end

    it "stamps resolved_at on the dispute" do
      dispute = create(:dispute)

      described_class.call(dispute, "won")

      expect(dispute.reload.resolved_at).to be_present
    end

    it "enqueues a dispute.won webhook when outcome is won" do
      dispute = create(:dispute)

      expect {
        described_class.call(dispute, "won")
      }.to have_enqueued_job(WebhookDeliveryJob).with(
        dispute.merchant_id, "dispute.won", "Dispute", dispute.id
      )
    end

    it "enqueues a dispute.lost webhook when outcome is lost" do
      dispute = create(:dispute)

      expect {
        described_class.call(dispute, "lost")
      }.to have_enqueued_job(WebhookDeliveryJob).with(
        dispute.merchant_id, "dispute.lost", "Dispute", dispute.id
      )
    end

    it "raises ValidationFailed when outcome is invalid" do
      dispute = create(:dispute)

      expect {
        described_class.call(dispute, "invalid")
      }.to raise_error(DisputeError::ValidationFailed)
    end

    it "raises AlreadyResolved when dispute is already won" do
      dispute = create(:dispute, :won)

      expect {
        described_class.call(dispute, "lost")
      }.to raise_error(DisputeError::AlreadyResolved)
    end

    it "raises AlreadyResolved when dispute is already lost" do
      dispute = create(:dispute, :lost)

      expect {
        described_class.call(dispute, "won")
      }.to raise_error(DisputeError::AlreadyResolved)
    end
  end
end
