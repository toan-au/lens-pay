class CleanupDemoMerchantsJob < ApplicationJob
  queue_as :default

  def perform
    Merchant.where(is_demo: true).where("demo_expires_at <= ?", Time.current).destroy_all
  end
end
