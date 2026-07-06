class Refund < ApplicationRecord
  include AASM

  belongs_to :payment, class_name: "Transaction", foreign_key: :transaction_id
  validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :idempotency_key, presence: true, uniqueness: true

  before_create :setup_refund

  enum :status, { pending: 0, succeeded: 1, failed: 2 }

  aasm column: :status, enum: true, whiny_transitions: true do
    state :pending, initial: true
    state :succeeded
    state :failed

    event :succeed do
      transitions from: :pending, to: :succeeded
    end

    event :decline do
      transitions from: :pending, to: :failed
    end
  end

  # Public payloads identify records by uid; integer PKs/FKs stay internal.
  def as_json(options = nil)
    super({ except: %i[id transaction_id] }.merge(options || {}))
  end

  private def setup_refund
    self.uid = "re_#{SecureRandom.uuid}"
  end
end
