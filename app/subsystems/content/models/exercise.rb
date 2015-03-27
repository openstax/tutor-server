class Content::Models::Exercise < Tutor::SubSystems::BaseModel
  acts_as_resource

  has_many :exercise_tags, dependent: :destroy
end
