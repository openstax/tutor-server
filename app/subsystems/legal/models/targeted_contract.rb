class Legal::Models::TargetedContract < Tutor::SubSystems::BaseModel

  def as_poro
    Legal::TargetedContract.new(self)
  end

end
