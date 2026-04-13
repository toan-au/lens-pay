require 'rails_helper'

RSpec.describe Transaction, type: :model do
  it "generates a uid with the tr_ prefix on create" do
    transaction = Transaction.create!(amount: 1000, currency: "JPY", idempotency_key: "test_key_1")

    expect(transaction.uid).to start_with("tr_")
  end
end
