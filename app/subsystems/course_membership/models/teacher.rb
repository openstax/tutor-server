class CourseMembership::Models::Teacher < Tutor::SubSystems::BaseModel

  belongs_to :role, subsystem: :entity
  belongs_to :course, subsystem: :course_profile

  validates :role,   presence: true, uniqueness: true
  validates :course, presence: true

  delegate :username, :first_name, :last_name, :full_name, :name, to: :role

end
