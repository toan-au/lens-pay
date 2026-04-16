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
  end
end
