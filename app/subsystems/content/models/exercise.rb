class Content::Models::Exercise < Tutor::SubSystems::BaseModel
  acts_as_resource

  sortable_has_many :exercise_topics, on: :number,
                                      dependent: :destroy,
                                      inverse_of: :exercise

end
