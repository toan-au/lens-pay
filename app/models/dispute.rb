class Dispute < ApplicationRecord
  include AASM

  belongs_to :payment, class_name: "Transaction", foreign_key: :transaction_id
  belongs_to :merchant

  has_many :dispute_responses, dependent: :destroy

  REASONS = %w[fraudulent unrecognized duplicate product_not_received product_unacceptable].freeze

  validates :reason,     presence: true, inclusion: { in: REASONS }
  validates :amount,     presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :currency,   presence: true
  validates :respond_by, presence: true

  before_create :setup_dispute

  enum :status, { open: 0, merchant_responded: 1, won: 2, lost: 3 }

  aasm column: :status, enum: true, whiny_transitions: true do
    state :open, initial: true
    state :merchant_responded
    state :won
    state :lost

    event :respond do
      transitions from: :open, to: :merchant_responded
    end

    event :win do
      transitions from: %i[open merchant_responded], to: :won
    end

    event :lose do
      transitions from: %i[open merchant_responded], to: :lost
    end
  end

  private

  def setup_dispute
    self.uid = "dis_#{SecureRandom.hex(12)}"
  end
end
