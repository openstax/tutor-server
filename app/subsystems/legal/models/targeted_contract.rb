class Legal::Models::TargetedContract < Tutor::SubSystems::BaseModel

  serialize :masked_contract_names, Array

  def as_poro
    Legal::TargetedContract.new(self)
  end
end
