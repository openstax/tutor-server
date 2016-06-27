class Legal::Models::TargetedContract < Tutor::SubSystems::BaseModel

  json_serialize :masked_contract_names, String, array: true

  def as_poro
    Legal::TargetedContract.new(self)
  end

end
