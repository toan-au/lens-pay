require 'rails_helper'

RSpec.describe Refund, type: :model do
  it "generates a uid with the re_ prefix on create" do
    refund = create(:refund)

    expect(refund.uid).to start_with("re_")
  end

  it "defaults to pending on create" do
    refund = create(:refund)

    expect(refund.status).to eq("pending")
  end

  describe "state machine" do
    it "transitions from pending to succeeded" do
      refund = create(:refund, status: :pending)

      expect { refund.succeed! }.to change { refund.status }.from("pending").to("succeeded")
    end

    it "transitions from pending to declined" do
      refund = create(:refund, status: :pending)

      expect { refund.decline! }.to change { refund.status }.from("pending").to("declined")
    end

    it "cannot transition from succeeded to declined" do
      refund = create(:refund, status: :succeeded)

      expect { refund.decline! }.to raise_error(AASM::InvalidTransition)
    end

    it "cannot transition from declined to succeeded" do
      refund = create(:refund, status: :declined)

      expect { refund.succeed! }.to raise_error(AASM::InvalidTransition)
    end
  end
end
