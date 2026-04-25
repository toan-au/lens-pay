class Refund < ApplicationRecord
  belongs_to :payment, class_name: "Transaction", foreign_key: :transaction_id
  validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :idempotency_key, presence: true, uniqueness: true

  before_create :setup_refund

  enum :status, { pending: 0, succeeded: 1, declined: 2 }

  private def setup_refund
    self.uid = "re_#{SecureRandom.uuid}"
  end
end
