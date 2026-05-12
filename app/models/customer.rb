class Customer < ApplicationRecord
  belongs_to :merchant
  has_many :payments, class_name: "Transaction", foreign_key: :customer_id

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  before_create :generate_uid

  scope :active, -> { where(deleted_at: nil) }

  def deleted? = deleted_at.present?

  def delete!
    update!(deleted_at: Time.current)
  end

  private

  def generate_uid
    self.uid ||= "cus_#{SecureRandom.uuid}"
  end
end
