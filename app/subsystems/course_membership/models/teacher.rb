class CourseMembership::Models::Teacher < Tutor::SubSystems::BaseModel
  belongs_to :role, subsystem: :entity
  belongs_to :course, subsystem: :entity

  validates :role,   presence: true, uniqueness: true
  validates :course, presence: true
end
