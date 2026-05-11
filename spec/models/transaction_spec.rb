require 'rails_helper'

RSpec.describe Transaction, type: :model do
  it "generates a uid with the tr_ prefix on create" do
    transaction = create(:transaction)

    expect(transaction.uid).to start_with("tr_")
  end

  it "starts in the pending state" do
    transaction = create(:transaction)

    expect(transaction.status).to eq("pending")
  end

  describe "state transitions" do
    it "transitions from pending to authorized" do
      transaction = create(:transaction)

      transaction.authorize!

      expect(transaction.status).to eq("authorized")
    end

    it "transitions from authorized to processing" do
      transaction = create(:transaction, :authorized)

      transaction.capture!

      expect(transaction.status).to eq("processing")
    end

    it "transitions from processing to succeeded" do
      transaction = create(:transaction, :processing)

      transaction.complete!

      expect(transaction.status).to eq("succeeded")
    end

    it "transitions from pending to declined" do
      transaction = create(:transaction)

      transaction.decline!

      expect(transaction.status).to eq("declined")
    end

    it "transitions from authorized to declined" do
      transaction = create(:transaction, :authorized)

      transaction.decline!

      expect(transaction.status).to eq("declined")
    end

    it "transitions from processing to declined" do
      transaction = create(:transaction, :processing)

      transaction.decline!

      expect(transaction.status).to eq("declined")
    end

    it "cannot skip from pending to processing" do
      transaction = create(:transaction)

      expect { transaction.capture! }.to raise_error(AASM::InvalidTransition)
    end

    it "cannot skip from pending to succeeded" do
      transaction = create(:transaction)

      expect { transaction.complete! }.to raise_error(AASM::InvalidTransition)
    end

    it "cannot transition from a terminal state" do
      transaction = create(:transaction, :succeeded)

      expect { transaction.decline! }.to raise_error(AASM::InvalidTransition)
    end

    it "transitions from pending to cancelled" do
      transaction = create(:transaction)

      transaction.cancel!

      expect(transaction.status).to eq("cancelled")
    end

    it "transitions from authorized to cancelled" do
      transaction = create(:transaction, :authorized)

      transaction.cancel!

      expect(transaction.status).to eq("cancelled")
    end

    it "cannot cancel a processing transaction" do
      transaction = create(:transaction, :processing)

      expect { transaction.cancel! }.to raise_error(AASM::InvalidTransition)
    end

    it "cannot cancel a succeeded transaction" do
      transaction = create(:transaction, :succeeded)

      expect { transaction.cancel! }.to raise_error(AASM::InvalidTransition)
    end

    it "transitions from pending to expired" do
      transaction = create(:transaction)

      transaction.expire!

      expect(transaction.status).to eq("expired")
    end

    it "cannot expire an authorized transaction" do
      transaction = create(:transaction, :authorized)

      expect { transaction.expire! }.to raise_error(AASM::InvalidTransition)
    end

    it "cannot expire a succeeded transaction" do
      transaction = create(:transaction, :succeeded)

      expect { transaction.expire! }.to raise_error(AASM::InvalidTransition)
    end
  end

  describe "expires_at" do
    it "is set to EXPIRY_WINDOW from now on create" do
      freeze_time do
        transaction = create(:transaction)

        expect(transaction.expires_at).to be_within(1.second).of(Transaction::EXPIRY_WINDOW.from_now)
      end
    end
  end

  describe "#refundable_amount" do
    it "subtracts succeeded refunds from captured amount" do
      transaction = create(:transaction, :succeeded, captured_amount: 1000)
      create(:refund, payment: transaction, amount: 400, status: :succeeded)

      expect(transaction.refundable_amount).to eq(600)
    end

    it "subtracts pending refunds from captured amount" do
      transaction = create(:transaction, :succeeded, captured_amount: 1000)
      create(:refund, payment: transaction, amount: 400, status: :pending)

      expect(transaction.refundable_amount).to eq(600)
    end

    it "does not subtract failed refunds from captured amount" do
      transaction = create(:transaction, :succeeded, captured_amount: 1000)
      create(:refund, payment: transaction, amount: 400, status: :failed)

      expect(transaction.refundable_amount).to eq(1000)
    end
  end
end
