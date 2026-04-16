module Merchants
  class CreateService
    Result = Data.define(:merchant, :status)

    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params
    end

    def call
      merchant = Merchant.new(@params)

      raise MerchantError::ValidationFailed, merchant.errors.full_messages unless merchant.save

      Result.new(merchant: merchant, status: :created)
    end
  end
end
