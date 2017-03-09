class Tasks::Models::TaskedPlaceholder < Tutor::SubSystems::BaseModel
  acts_as_tasked

  enum placeholder_type: [:unknown_type, :exercise_type]

  validates :placeholder_type, presence: true

  def placeholder?
    true
  end

  def is_correct?
    false
  end

  def completed?
    false
  end
end
