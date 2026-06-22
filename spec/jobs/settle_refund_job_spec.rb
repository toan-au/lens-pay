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

      expect(refund.reload.status).to eq("failed")
    end

    context "when a request_id is provided" do
      it "restores Current.request_id during execution" do
        refund = create(:refund, status: :pending)
        allow(Refunds::SucceedService).to receive(:call) do
          expect(Current.request_id).to eq("trace-xyz")
        end

        described_class.perform_now(refund.id, request_id: "trace-xyz")
      end

      it "resets Current.request_id after job completes" do
        refund = create(:refund, status: :pending)

        described_class.perform_now(refund.id, request_id: "trace-xyz")

        expect(Current.request_id).to be_nil
      end

      it "resets Current.request_id even when job raises" do
        refund = create(:refund, status: :pending)
        allow(Refunds::SucceedService).to receive(:call).and_raise(StandardError, "processor error")

        expect { described_class.perform_now(refund.id, request_id: "trace-xyz") }
          .to raise_error(StandardError, "processor error")

        expect(Current.request_id).to be_nil
      end
    end
  end
end
