class WebhookEvent < ApplicationRecord
  belongs_to :merchant

  # No uid column; integer id is the public identifier. FKs stay internal.
  def as_json(options = nil)
    super({ except: %i[merchant_id] }.merge(options || {}))
  end
end
