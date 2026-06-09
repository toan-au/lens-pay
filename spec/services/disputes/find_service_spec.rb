require 'rails_helper'

RSpec.describe Disputes::FindService do
  describe ".call" do
    it "returns the dispute when found" do
      merchant = create(:merchant)
      dispute  = create(:dispute, merchant: merchant)

      result = described_class.call(merchant, dispute.uid)

      expect(result.dispute).to eq(dispute)
    end

    it "raises DisputeError::NotFound when the dispute does not exist" do
      merchant = create(:merchant)

      expect { described_class.call(merchant, "dis_nonexistent") }.to raise_error(DisputeError::NotFound)
    end

    it "raises DisputeError::NotFound for another merchant's dispute" do
      merchant       = create(:merchant)
      other_merchant = create(:merchant)
      dispute        = create(:dispute, merchant: other_merchant)

      expect { described_class.call(merchant, dispute.uid) }.to raise_error(DisputeError::NotFound)
    end
  end
end
