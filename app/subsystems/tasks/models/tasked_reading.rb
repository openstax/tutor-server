class Tasks::Models::TaskedReading < Tutor::SubSystems::BaseModel
  acts_as_tasked

  serialize :book_location, Array

  validates :url, presence: true
  validates :content, presence: true

  def has_content?
    true
  end
end
