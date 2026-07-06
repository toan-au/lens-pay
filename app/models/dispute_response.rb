class DisputeResponse < ApplicationRecord
  belongs_to :dispute

  validates :evidence, presence: true

  # No uid column; integer id is the public identifier. FKs stay internal.
  def as_json(options = nil)
    super({ except: %i[dispute_id] }.merge(options || {}))
  end
end
