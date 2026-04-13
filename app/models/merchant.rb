class Merchant < ApplicationRecord
    has_many :transactions, dependent: :destroy
    has_secure_password :api_key, validations: false

    before_create :setup_merchant

    attr_accessor :raw_api_key

    def setup_merchant
        self.uid = "mch_#{SecureRandom.uuid}"
        self.raw_api_key = "sk_#{SecureRandom.hex(24)}"
        self.api_key = raw_api_key
    end
end
