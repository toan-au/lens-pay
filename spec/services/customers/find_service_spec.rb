require 'rails_helper'

RSpec.describe Customers::FindService do
  let(:merchant) { create(:merchant) }
  let(:customer) { create(:customer, merchant:) }

  describe ".call" do
    it "returns the customer for a known uid" do
      result = described_class.call(merchant, customer.uid)

      expect(result.status).to eq(:ok)
      expect(result.customer).to eq(customer)
    end

    it "raises NotFound for an unknown uid" do
      expect {
        described_class.call(merchant, "cus_unknown")
      }.to raise_error(CustomerError::NotFound)
    end

    it "raises NotFound for a customer belonging to another merchant" do
      other_merchant = create(:merchant)
      other_customer = create(:customer, merchant: other_merchant)

      expect {
        described_class.call(merchant, other_customer.uid)
      }.to raise_error(CustomerError::NotFound)
    end

    it "still finds a deleted customer" do
      customer.delete!

      result = described_class.call(merchant, customer.uid)

      expect(result.customer).to eq(customer)
    end
  end
end
