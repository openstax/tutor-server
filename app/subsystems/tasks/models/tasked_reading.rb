class Tasks::Models::TaskedReading < Tutor::SubSystems::BaseModel
  acts_as_tasked

  serialize :chapter_section, Array

  validates :url, presence: true
  validates :content, presence: true
end
