class Tasks::Models::TaskedReading < Tutor::SubSystems::BaseModel
  acts_as_tasked

  validates :url, presence: true
  validates :content, presence: true
end
