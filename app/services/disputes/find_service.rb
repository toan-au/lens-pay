module Disputes
  class FindService
    Result = Data.define(:dispute, :status)

    def self.call(current_merchant, uid)
      new(current_merchant, uid).call
    end

    def initialize(current_merchant, uid)
      @current_merchant = current_merchant
      @uid = uid
    end

    def call
      dispute = @current_merchant.disputes.find_by(uid: @uid)

      raise DisputeError::NotFound unless dispute
      Result.new(dispute:, status: :ok)
    end
  end
end
