require 'rails_helper'

RSpec.describe Merchant, type: :model do
  it "generates a uid with the mch_ prefix on create" do
    merchant = create(:merchant)

    expect(merchant.uid).to start_with("mch_")
  end

  it "generates a raw_api_key with the sk_ prefix on create" do
    merchant = create(:merchant)

    expect(merchant.raw_api_key).to start_with("sk_")
  end

  it "does not store the raw api key in the database" do
    merchant = create(:merchant)

    expect(merchant.api_key_digest).not_to eq(merchant.raw_api_key)
  end

  it "defaults to active status on create" do
    merchant = create(:merchant)

    expect(merchant).to be_active
  end

  it "generates a webhook_secret with the whs_ prefix on create" do
    merchant = create(:merchant)

    expect(merchant.webhook_secret).to start_with("whs_")
  end

  it "stores the webhook_secret in plaintext" do
    merchant = create(:merchant)

    expect(Merchant.find(merchant.id).webhook_secret).to eq(merchant.webhook_secret)
  end

  it "accepts a valid webhook_url" do
    merchant = build(:merchant, webhook_url: "https://example.com/webhooks")

    expect(merchant).to be_valid
  end

  it "rejects a webhook_url that is not a valid URL" do
    merchant = build(:merchant, webhook_url: "not-a-url")

    expect(merchant).not_to be_valid
  end

  it "rejects a webhook_url with an embedded newline" do
    merchant = build(:merchant, webhook_url: "https://evil.com\ninjected")

    expect(merchant).not_to be_valid
  end

  it "allows webhook_url to be blank" do
    merchant = build(:merchant, webhook_url: nil)

    expect(merchant).to be_valid
  end
end
