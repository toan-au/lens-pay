require "rails_helper"

RSpec.describe Refunds::ListByPaymentService do
  it "returns an array of refunds for a given transaction" do
    transaction = create(:transaction, :succeeded, captured_amount: 1000)
    create(:refund, payment: transaction)
    result = described_class.call(transaction)

    expect(result.status).to eq(:ok)
    expect(result.refunds.count).to eq(1)
  end

  it "returns an empty array when there are no refunds" do
    transaction = create(:transaction, :succeeded, captured_amount: 1000)

    result = described_class.call(transaction)

    expect(result.status).to eq(:ok)
    expect(result.refunds).to eq([])
  end

  it "does not return refunds from other transactions" do
    transaction = create(:transaction, :succeeded, captured_amount: 1000)
    other_transaction = create(:transaction, :succeeded, captured_amount: 1000)
    create(:refund, payment: transaction, amount: 500)
    create(:refund, payment: other_transaction, amount: 500)

    result = described_class.call(transaction)

    expect(result.refunds.count).to eq(1)
  end
end
