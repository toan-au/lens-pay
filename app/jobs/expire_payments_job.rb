class ExpirePaymentsJob < ApplicationJob
  queue_as :payments

  def perform
    Transaction.pending.where(expires_at: ..Time.current).find_each do |transaction|
      Payments::ExpireService.call(transaction)
    rescue => e
      AuditLogger.log(event: "payment.expire_failed", error: e, transaction_uid: transaction.uid)
    end
  end
end
