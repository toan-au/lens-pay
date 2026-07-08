class Merchant < ApplicationRecord
  has_many :transactions, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :webhook_events, dependent: :destroy
  has_many :disputes

  enum :status, { pending: 0, active: 1, suspended: 2 }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :country, presence: true, length: { is: 2 }
  validates :currency, presence: true, inclusion: { in: Money::Currency.all.map(&:iso_code) }
  validates :status, presence: true
  validates :webhook_url, format: { with: /\Ahttps?:\/\/.+\z/, message: "must be a valid HTTP or HTTPS URL" }, allow_blank: true

  attr_reader :raw_api_key

  before_create :setup_merchant

  private

  def setup_merchant
    self.uid = "mch_#{SecureRandom.uuid}"
    @raw_api_key = "sk_#{SecureRandom.hex(24)}"
    self.api_key_digest = Digest::SHA256.hexdigest(@raw_api_key)
    self.webhook_secret = "whs_#{SecureRandom.hex(24)}"

    # Default to the built-in webhook sink so the delivery loop is visible in
    # the dashboard; merchants who registered with their own URL keep it.
    if webhook_url.blank?
      self.webhook_url = "#{Rails.application.config.app_host}/api/v1/webhooks/#{self.uid}"
    end

    # We'll just make all accounts active
    self.status = :active
  end
end
