class Content::Models::Exercise < Tutor::SubSystems::BaseModel
  acts_as_resource

  has_many :exercise_tags, dependent: :destroy

  has_many :tasked_exercises, subsystem: :tasks, dependent: :destroy, foreign_key: :exercise_id
end
