require 'rails_helper'

RSpec.describe Transaction, type: :model do
  it "generates a uid with the tr_ prefix on create" do
    transaction = create(:transaction)

    expect(transaction.uid).to start_with("tr_")
  end
end
