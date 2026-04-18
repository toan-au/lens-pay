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
end
