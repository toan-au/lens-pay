class Transaction < ApplicationRecord
    validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
    validates :currency, presence: true, inclusion: { in: %w[JPY USD EUR], message: "%{value} is not a supported currency" }
    validates :idempotency_key, presence: true, uniqueness: true
end
