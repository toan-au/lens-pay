require "rails_helper"

RSpec.describe CleanupDemoMerchantsJob, type: :job do
  it "deletes demo merchants whose demo_expires_at has passed" do
    expired = create(:merchant, is_demo: true, demo_expires_at: 1.hour.ago)

    described_class.perform_now

    expect(Merchant.find_by(id: expired.id)).to be_nil
  end

  it "does not delete demo merchants that have not yet expired" do
    active = create(:merchant, is_demo: true, demo_expires_at: 1.hour.from_now)

    described_class.perform_now

    expect(Merchant.find_by(id: active.id)).to be_present
  end

  it "does not delete non-demo merchants" do
    regular = create(:merchant, is_demo: false)

    described_class.perform_now

    expect(Merchant.find_by(id: regular.id)).to be_present
  end
end
