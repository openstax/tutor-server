class Tasks::Models::TaskedPlaceholder < Tutor::SubSystems::BaseModel
  acts_as_tasked

  enum placeholder_type: [:default_type, :exercise_type]

  validates :placeholder_type, presence: true

  def placeholder?
    true
  end

  def placeholder_name
    placeholder_type.gsub(/_type\z/, '').gsub('_', ' ')
  end
end
