require 'rails_helper'

RSpec.describe Disputes::ListService do
  describe ".call" do
    it "returns disputes scoped to the merchant" do
      merchant       = create(:merchant)
      other_merchant = create(:merchant)
      create_list(:dispute, 3, merchant: merchant)
      create_list(:dispute, 2, merchant: other_merchant)

      result = described_class.call(merchant)

      expect(result.disputes.count).to eq(3)
      expect(result.disputes).to all(have_attributes(merchant: merchant))
    end

    it "filters by status" do
      merchant = create(:merchant)
      create(:dispute, merchant: merchant)
      create(:dispute, :won, merchant: merchant)
      create(:dispute, :lost, merchant: merchant)

      result = described_class.call(merchant, status: "open")

      expect(result.disputes.count).to eq(1)
      expect(result.disputes.first.status).to eq("open")
    end

    it "returns disputes ordered newest first" do
      merchant = create(:merchant)
      old_dispute = create(:dispute, merchant: merchant, created_at: 2.days.ago)
      new_dispute = create(:dispute, merchant: merchant, created_at: 1.day.ago)

      result = described_class.call(merchant)

      expect(result.disputes.first).to eq(new_dispute)
      expect(result.disputes.last).to eq(old_dispute)
    end

    it "defaults to a limit of 25" do
      merchant = create(:merchant)
      create_list(:dispute, 30, merchant: merchant)

      result = described_class.call(merchant)

      expect(result.disputes.count).to eq(25)
    end

    it "respects a custom limit" do
      merchant = create(:merchant)
      create_list(:dispute, 10, merchant: merchant)

      result = described_class.call(merchant, limit: 4)

      expect(result.disputes.count).to eq(4)
    end

    it "returns next_cursor when there are more results" do
      merchant = create(:merchant)
      create_list(:dispute, 30, merchant: merchant)

      result = described_class.call(merchant)

      expect(result.next_cursor).to start_with("dis_")
    end

    it "returns next_cursor nil when on the last page" do
      merchant = create(:merchant)
      create_list(:dispute, 5, merchant: merchant)

      result = described_class.call(merchant)

      expect(result.next_cursor).to be_nil
    end

    it "paginates using the cursor" do
      merchant = create(:merchant)
      create_list(:dispute, 30, merchant: merchant)

      first_page  = described_class.call(merchant)
      second_page = described_class.call(merchant, cursor: first_page.next_cursor)

      first_uids  = first_page.disputes.map(&:uid)
      second_uids = second_page.disputes.map(&:uid)

      expect(second_uids.count).to eq(5)
      expect(second_uids & first_uids).to be_empty
    end
  end
end
