class Legal::Models::TargetedContract < ApplicationRecord
  def as_poro
    Legal::TargetedContract.new(self)
  end
end
