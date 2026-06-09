class DisputeResponse < ApplicationRecord
  belongs_to :dispute

  validates :evidence, presence: true
end
