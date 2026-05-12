require 'rails_helper'

RSpec.describe Customers::CreateService do
  let(:merchant) { create(:merchant) }

  describe ".call" do
    it "creates a customer and returns :created" do
      result = described_class.call(merchant, { name: "Jane Doe", email: "jane@example.com" })

      expect(result.status).to eq(:created)
      expect(result.customer).to be_persisted
      expect(result.customer.uid).to start_with("cus_")
    end

    it "scopes the customer to the merchant" do
      result = described_class.call(merchant, { name: "Jane Doe", email: "jane@example.com" })

      expect(result.customer.merchant).to eq(merchant)
    end

    it "stores optional metadata" do
      result = described_class.call(merchant, { name: "Jane", email: "jane@example.com", metadata: { tier: "gold" } })

      expect(result.customer.metadata).to eq({ "tier" => "gold" })
    end

    it "raises ValidationFailed when name is missing" do
      expect {
        described_class.call(merchant, { email: "jane@example.com" })
      }.to raise_error(CustomerError::ValidationFailed)
    end

    it "raises ValidationFailed when email is missing" do
      expect {
        described_class.call(merchant, { name: "Jane Doe" })
      }.to raise_error(CustomerError::ValidationFailed)
    end

    it "raises ValidationFailed when email is malformed" do
      expect {
        described_class.call(merchant, { name: "Jane Doe", email: "not-an-email" })
      }.to raise_error(CustomerError::ValidationFailed)
    end
  end
end
