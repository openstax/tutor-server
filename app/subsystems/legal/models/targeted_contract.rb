class Legal::Models::TargetedContract < ApplicationRecord

  json_serialize :masked_contract_names, String, array: true

  def as_poro
    Legal::TargetedContract.new(self)
  end

end
