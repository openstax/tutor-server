class CourseProfile::Models::Profile < Tutor::SubSystems::BaseModel
  belongs_to :course, subsystem: :entity

  validates :name, presence: true
end
