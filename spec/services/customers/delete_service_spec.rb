require 'rails_helper'

RSpec.describe Customers::DeleteService do
  let(:merchant) { create(:merchant) }
  let(:customer) { create(:customer, merchant:) }

  describe ".call" do
    it "soft-deletes the customer and returns :ok" do
      result = described_class.call(merchant, customer.uid)

      expect(result.status).to eq(:ok)
      expect(result.customer.deleted_at).to be_present
    end

    it "excludes the customer from the active scope after deletion" do
      described_class.call(merchant, customer.uid)

      expect(merchant.customers.active).not_to include(customer)
    end

    it "raises NotFound for an unknown uid" do
      expect {
        described_class.call(merchant, "cus_unknown")
      }.to raise_error(CustomerError::NotFound)
    end

    it "raises NotFound when the customer is already deleted" do
      customer.delete!

      expect {
        described_class.call(merchant, customer.uid)
      }.to raise_error(CustomerError::NotFound)
    end
  end
end
