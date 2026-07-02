module Customers
  class FindService
    Result = Data.define(:customer, :status)

    def self.call(merchant, uid)
      new(merchant, uid).call
    end

    def initialize(merchant, uid)
      @merchant = merchant
      @uid = uid
    end

    def call
      customer = @merchant.customers.find_by(uid: @uid)
      raise CustomerError::NotFound unless customer

      Result.new(customer:, status: :ok)
    end
  end
end
