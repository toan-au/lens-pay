module Payments
  class ListService
    Result = Data.define(:transactions, :next_cursor, :status)

    def self.call(current_merchant, cursor: nil, status: nil, limit: 25)
      new(current_merchant, cursor:, status:, limit:).call
    end

    def initialize(current_merchant, cursor:, status:, limit:)
      @current_merchant = current_merchant
      @cursor = cursor
      @status = status
      @limit = limit
    end

    def call
      transactions = @current_merchant.transactions

      transactions = transactions.where(status: @status) if @status.present?

      if @cursor.present?
        cursor_record = Transaction.find_by!(uid: @cursor)
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
  end
end
