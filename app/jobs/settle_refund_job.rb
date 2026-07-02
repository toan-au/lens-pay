class SettleRefundJob < ApplicationJob
  queue_as :payments

  def perform(refund_id, request_id: nil)
    Current.request_id = request_id
    refund = Refund.find(refund_id)

    Refunds::SucceedService.call(refund)
  rescue => e
    Refunds::DeclineService.call(refund)
    raise e
  ensure
    Current.reset
  end
end
