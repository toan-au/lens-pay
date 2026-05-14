require 'rails_helper'

RSpec.describe Customers::ListService do
  let(:merchant) { create(:merchant) }

  describe ".call" do
    it "returns active customers for the merchant" do
      customer = create(:customer, merchant:)

      result = described_class.call(merchant)

      expect(result.status).to eq(:ok)
      expect(result.customers).to include(customer)
    end

    it "excludes deleted customers" do
      active = create(:customer, merchant:)
      deleted = create(:customer, merchant:, email: "deleted@example.com")
      deleted.delete!

      result = described_class.call(merchant)

      expect(result.customers).to include(active)
      expect(result.customers).not_to include(deleted)
    end

    it "excludes customers from other merchants" do
      other_merchant = create(:merchant)
      create(:customer, merchant: other_merchant)
      own_customer = create(:customer, merchant:)

      result = described_class.call(merchant)

      expect(result.customers).to eq([ own_customer ])
    end

    it "returns customers newest first" do
      first = create(:customer, merchant:, email: "first@example.com")
      second = create(:customer, merchant:, email: "second@example.com")

      result = described_class.call(merchant)

      expect(result.customers).to eq([ second, first ])
    end

    it "paginates with a cursor" do
      customers = create_list(:customer, 3, merchant:).reverse
      cursor = customers.first.uid

      result = described_class.call(merchant, cursor:)

      expect(result.customers).to eq(customers[1..])
    end

    it "sets next_cursor when there are more results" do
      create_list(:customer, 3, merchant:)

      result = described_class.call(merchant, limit: 2)

      expect(result.next_cursor).to be_present
    end

    it "sets next_cursor to nil on the last page" do
      create_list(:customer, 2, merchant:)

      result = described_class.call(merchant, limit: 2)

      expect(result.next_cursor).to be_nil
    end
  end
end
