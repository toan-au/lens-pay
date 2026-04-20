module Payments
  class ListService < ApplicationService
    Result = Data.define(:transactions, :next_cursor, :status)

    def initialize(merchant, cursor: nil, status: nil, limit: nil)
      default_limit = 25

      @merchant = merchant
      @cursor = cursor
      @status = status
      @limit = limit&.nonzero? || default_limit
    end

    def perform
      transactions = @merchant.transactions

      transactions = transactions.where(status: @status) if @status.present?

      if @cursor.present?
        cursor_record = @merchant.transactions.find_by!(uid: @cursor)
        # Paginate results before the given cursor (created_at, id) for keyset pagination
        transactions = transactions.where("(created_at, id) < (?, ?)", cursor_record.created_at, cursor_record.id)
      end

      transactions = transactions.order(created_at: :desc, id: :desc)
      transactions = transactions.limit(@limit + 1)

      next_cursor = nil
      if transactions.length > @limit
        transactions = transactions.first(@limit)
        last = transactions.last
        next_cursor = last.uid
      end

      Result.new(transactions:, next_cursor:, status: :ok)
    end

    def event_name
      "payment.listed"
    end

    def log_context
      {
        merchant_uid: @merchant.uid
      }
    end
  end
end
