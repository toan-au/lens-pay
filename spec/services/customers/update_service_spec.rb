require 'rails_helper'

RSpec.describe Customers::UpdateService do
  let(:merchant) { create(:merchant) }
  let(:customer) { create(:customer, merchant:) }

  describe ".call" do
    it "updates allowed fields and returns :ok" do
      result = described_class.call(merchant, customer.uid, { name: "Updated Name", email: "new@example.com" })

      expect(result.status).to eq(:ok)
      expect(result.customer.name).to eq("Updated Name")
      expect(result.customer.email).to eq("new@example.com")
    end

    it "updates metadata" do
      result = described_class.call(merchant, customer.uid, { metadata: { vip: true } })

      expect(result.customer.metadata).to eq({ "vip" => true })
    end

    it "raises NotFound for an unknown uid" do
      expect {
        described_class.call(merchant, "cus_unknown", { name: "X" })
      }.to raise_error(CustomerError::NotFound)
    end

    it "raises NotFound for a deleted customer" do
      customer.delete!

      expect {
        described_class.call(merchant, customer.uid, { name: "X" })
      }.to raise_error(CustomerError::NotFound)
    end

    it "raises ValidationFailed when setting name to nil" do
      expect {
        described_class.call(merchant, customer.uid, { name: nil })
      }.to raise_error(CustomerError::ValidationFailed)
    end

    it "raises ValidationFailed when setting email to a malformed address" do
      expect {
        described_class.call(merchant, customer.uid, { email: "bad" })
      }.to raise_error(CustomerError::ValidationFailed)
    end

    it "ignores unpermitted params" do
      original_uid = customer.uid
      described_class.call(merchant, customer.uid, { uid: "cus_hacked", name: "Fine" })

      expect(customer.reload.uid).to eq(original_uid)
    end
  end
end
