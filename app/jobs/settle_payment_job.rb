class SettlePaymentJob < ApplicationJob
  queue_as :payments

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)

    Payments::CompleteService.call(transaction)
  rescue => e
    Payments::DeclineService.call(transaction)
    raise e
  end
end
