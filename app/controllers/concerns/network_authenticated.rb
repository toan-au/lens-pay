# Authenticates the simulated card network via a shared secret. Used by the
# network-only endpoints (dispute lifecycle, payment confirmation) that no
# merchant may call.
module NetworkAuthenticated
  extend ActiveSupport::Concern

  included do
    before_action :verify_network_secret
  end

  private

  def verify_network_secret
    expected = ENV["NETWORK_SECRET"]
    provided = request.headers["X-Network-Secret"]

    unless expected.present? && ActiveSupport::SecurityUtils.secure_compare(provided.to_s, expected)
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
