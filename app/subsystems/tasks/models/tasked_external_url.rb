class Tasks::Models::TaskedExternalUrl < Tutor::SubSystems::BaseModel
  acts_as_tasked

  validates :url, presence: true
end
