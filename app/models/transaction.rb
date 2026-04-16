class Transaction < ApplicationRecord
  include AASM

  belongs_to :merchant

  validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true, inclusion: { in: Money::Currency.all.map(&:iso_code), message: "%{value} is not a supported currency" }
  validates :idempotency_key, presence: true, uniqueness: true

  before_create :setup_transaction

  enum :status, { pending: 0, authorized: 1, processing: 2, succeeded: 3, declined: 4 }

  aasm column: :status, enum: true, whiny_transitions: true do
    state :pending, initial: true
    state :authorized
    state :processing
    state :succeeded
    state :declined

    event :authorize do
      transitions from: :pending, to: :authorized
    end

    event :capture do
      transitions from: :authorized, to: :processing
    end

    event :complete do
      transitions from: :processing, to: :succeeded
    end

    event :decline do
      transitions from: %i[pending authorized processing], to: :declined
    end
  end

  private def setup_transaction
    self.uid = "tr_#{SecureRandom.uuid}"
  end
end
