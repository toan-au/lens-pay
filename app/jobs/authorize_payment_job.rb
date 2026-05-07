class AuthorizePaymentJob < ApplicationJob
  queue_as :payments

  def perform(transaction_id)
    sleep 2

    transaction = Transaction.find(transaction_id)

    Payments::AuthorizeService.call(transaction)
  rescue => e
    Payments::DeclineService.call(transaction)
    raise e
  end
end
