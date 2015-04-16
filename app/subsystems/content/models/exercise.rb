class Content::Models::Exercise < Tutor::SubSystems::BaseModel
  acts_as_resource

  wrapped_by ::Exercise

  has_many :exercise_tags, dependent: :destroy

  has_many :tasked_exercises, subsystem: :tasks,
                              dependent: :destroy
  protected :tasked_exercises
end
