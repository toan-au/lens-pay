require 'rails_helper'

RSpec.describe Refunds::SucceedService do
  describe ".call" do
    it "transitions a pending refund to succeeded" do
      refund = create(:refund, status: :pending)

      result = described_class.call(refund)

      expect(result.status).to eq(:ok)
      expect(refund.reload.status).to eq("succeeded")
    end

    it "raises InvalidTransition when refund is not pending" do
      refund = create(:refund, status: :declined)

      expect { described_class.call(refund) }.to raise_error(RefundError::InvalidTransition)
    end
  end
end
