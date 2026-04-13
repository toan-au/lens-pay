class Merchant < ApplicationRecord
  has_many :transactions, dependent: :destroy

  attr_reader :raw_api_key

  before_create :setup_merchant

  private

  def setup_merchant
    self.uid = "mch_#{SecureRandom.uuid}"
    @raw_api_key = "sk_#{SecureRandom.hex(24)}"
    self.api_key_digest = Digest::SHA256.hexdigest(@raw_api_key)
  end
end
