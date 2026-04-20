module Merchants
  class CreateService < ApplicationService
    Result = Data.define(:merchant, :status)

    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params
    end

    def perform
      @merchant = Merchant.new(@params)

      raise MerchantError::ValidationFailed, @merchant.errors.full_messages unless @merchant.save

      Result.new(merchant: @merchant, status: :created)
    end

    def event_name
      "merchant.created"
    end

    def log_context
      {
        merchant_uid: @merchant.uid,
        merchant_name: @merchant.name
      }
    end
  end
end
