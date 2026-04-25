class SettleRefundJob < ApplicationJob
  queue_as :payments

  def perform(refund_id)
    refund = Refund.find(refund_id)

    Refunds::SucceedService.call(refund)
  rescue => e
    Refunds::DeclineService.call(refund)
    raise e
  end
end
