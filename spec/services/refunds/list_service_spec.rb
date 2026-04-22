require "rails_helper"

RSpec.describe Refunds::ListService do
  it "returns an array of refunds for a given merchant" do
    merchant = create(:merchant)
    transaction1 = create(:transaction, merchant:)
    transaction2 = create(:transaction, merchant:)
    create(:refund, payment: transaction1)
    create(:refund, payment: transaction2)

    result = described_class.call(merchant)

    expect(result.status).to eq(:ok)
    expect(result.refunds.count).to eq(2)
  end

  it "returns an empty array when there are no refunds" do
    merchant = create(:merchant)

    result = described_class.call(merchant)

    expect(result.status).to eq(:ok)
    expect(result.refunds.count).to eq(0)
  end

  it "filters the list of refunds by provided filter query" do
    merchant = create(:merchant)

    transaction = create(:transaction, merchant:, status: "succeeded")
    transaction2 = create(:transaction, merchant:)

    create(:refund, payment: transaction, status: "pending")
    create(:refund, payment: transaction, status: "succeeded")
    create(:refund, payment: transaction2, status: "succeeded")

    result = described_class.call(merchant, status: "succeeded")

    expect(result.status).to eq(:ok)
    expect(result.refunds.count).to eq(2)
    expect(result.refunds.first.status).to eq("succeeded")
  end

  it "limits the number of returned items by a provided limit" do
    merchant = create(:merchant)

    transaction = create(:transaction, merchant:, status: "succeeded")
    transaction2 = create(:transaction, merchant:)

    create_list(:refund, 10, payment: transaction)
    create_list(:refund, 15, payment: transaction)

    limit = 20
    result = described_class.call(merchant, limit:)

    expect(result.status).to eq(:ok)
    expect(result.refunds.count).to eq(limit)
  end

  it "pagination with cursor works" do
    merchant = create(:merchant)
    transaction = create(:transaction, merchant:, status: "succeeded")
    create_list(:refund, 10, payment: transaction)

    first_page = described_class.call(merchant, limit: 5)
    expect(first_page.refunds.count).to eq(5)
    expect(first_page.next_cursor).to start_with("re_")

    second_page = described_class.call(merchant, limit: 5, cursor: first_page.next_cursor)
    expect(second_page.refunds.count).to eq(5)
    expect(second_page.next_cursor).to be_nil
  end

  it "does not return refunds from other merchants" do
    merchant = create(:merchant)
    other_merchant = create(:merchant)
    transaction = create(:transaction, merchant:, status: "succeeded")
    other_transaction = create(:transaction, merchant: other_merchant, status: "succeeded")
    create(:refund, payment: transaction)
    create(:refund, payment: other_transaction)

    result = described_class.call(merchant)

    expect(result.refunds.count).to eq(1)
  end
end
