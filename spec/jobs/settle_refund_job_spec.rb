require 'rails_helper'

RSpec.describe SettleRefundJob, type: :job do
  describe "#perform" do
    it "marks a refund as succeeded" do
      refund = create(:refund, status: :pending)

      described_class.perform_now(refund.id)

      expect(refund.reload.status).to eq("succeeded")
    end

    it "declines the refund and re-raises if processing fails" do
      refund = create(:refund, status: :pending)
      allow(Refunds::SucceedService).to receive(:call).and_raise(StandardError, "processor error")

      expect { described_class.perform_now(refund.id) }.to raise_error(StandardError, "processor error")

      expect(refund.reload.status).to eq("declined")
    end
  end
end
