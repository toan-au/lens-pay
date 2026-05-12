class Transaction < ApplicationRecord
  include AASM

  belongs_to :merchant
  belongs_to :customer, optional: true
  has_many :refunds

  validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true, inclusion: { in: Money::Currency.all.map(&:iso_code), message: "%{value} is not a supported currency" }
  validates :idempotency_key, presence: true, uniqueness: true

  before_create :setup_transaction

  EXPIRY_WINDOW = 3.days

  enum :status, { pending: 0, authorized: 1, processing: 2, succeeded: 3, declined: 4, cancelled: 5, expired: 6 }

  aasm column: :status, enum: true, whiny_transitions: true do
    state :pending, initial: true
    state :authorized
    state :processing
    state :succeeded
    state :declined
    state :cancelled
    state :expired

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

    event :cancel do
      transitions from: %i[pending authorized], to: :cancelled
    end

    event :expire do
      transitions from: :pending, to: :expired
    end
  end

  def refundable_amount
    captured_amount - self.refunds.where(status: [ :pending, :succeeded ]).sum(:amount)
  end


  private def setup_transaction
    self.uid = "tr_#{SecureRandom.uuid}"
    self.expires_at ||= EXPIRY_WINDOW.from_now
  end
end
