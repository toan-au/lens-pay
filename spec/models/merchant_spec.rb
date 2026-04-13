require 'rails_helper'

RSpec.describe Merchant, type: :model do
  it "generates a uid with the mch_ prefix on create" do
    merchant = Merchant.create!(name: "Test Merchant")

    expect(merchant.uid).to start_with("mch_")
  end
end
