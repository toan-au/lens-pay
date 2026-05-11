require 'rails_helper'

RSpec.describe ExpirePaymentsJob, type: :job do
  describe "#perform" do
    it "expires pending payments past their expires_at" do
      expired = create(:transaction, expires_at: 1.hour.ago)
      still_valid = create(:transaction, expires_at: 1.hour.from_now)

      described_class.new.perform

      expect(expired.reload.status).to eq("expired")
      expect(still_valid.reload.status).to eq("pending")
    end

    it "does not expire non-pending payments" do
      authorized = create(:transaction, :authorized, expires_at: 1.hour.ago)

      described_class.new.perform

      expect(authorized.reload.status).to eq("authorized")
    end

    it "enqueues a webhook for each expired payment" do
      create(:transaction, expires_at: 1.hour.ago)
      create(:transaction, expires_at: 1.hour.ago)

      expect {
        described_class.new.perform
      }.to have_enqueued_job(WebhookDeliveryJob).exactly(2).times
    end
  end
end
