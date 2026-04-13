class Transaction < ApplicationRecord
    belongs_to :merchant

    validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
    validates :currency, presence: true, inclusion: { in: Money::Currency.all.map(&:iso_code), message: "%{value} is not a supported currency" }
    validates :idempotency_key, presence: true, uniqueness: true

    before_create :setup_transaction

    private def setup_transaction
        self.uid = "tr_#{SecureRandom.uuid}"
    end
end
