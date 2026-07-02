require 'rails_helper'

RSpec.describe Customer, type: :model do
  let(:merchant) { create(:merchant) }

  it "generates a uid with the cus_ prefix on create" do
    customer = create(:customer, merchant:)

    expect(customer.uid).to start_with("cus_")
  end

  describe "validations" do
    it "is valid with a name and email" do
      customer = build(:customer, merchant:)

      expect(customer).to be_valid
    end

    it "requires a name" do
      customer = build(:customer, merchant:, name: nil)

      expect(customer).not_to be_valid
    end

    it "requires an email" do
      customer = build(:customer, merchant:, email: nil)

      expect(customer).not_to be_valid
    end

    it "rejects a malformed email" do
      customer = build(:customer, merchant:, email: "not-an-email")

      expect(customer).not_to be_valid
    end

    it "allows metadata to be nil" do
      customer = build(:customer, merchant:, metadata: nil)

      expect(customer).to be_valid
    end
  end

  describe "soft delete" do
    it "is not deleted by default" do
      customer = create(:customer, merchant:)

      expect(customer).not_to be_deleted
    end

    it "sets deleted_at when deleted" do
      customer = create(:customer, merchant:)

      customer.delete!

      expect(customer.deleted_at).to be_present
    end

    it "is included in the active scope when not deleted" do
      customer = create(:customer, merchant:)

      expect(Customer.active).to include(customer)
    end

    it "is excluded from the active scope when deleted" do
      customer = create(:customer, merchant:)
      customer.delete!

      expect(Customer.active).not_to include(customer)
    end
  end

  describe "associations" do
    it "belongs to a merchant" do
      customer = create(:customer, merchant:)

      expect(customer.merchant).to eq(merchant)
    end

    it "has many payments" do
      customer = create(:customer, merchant:)
      payment = create(:transaction, merchant:, customer:)

      expect(customer.payments).to include(payment)
    end
  end
end
