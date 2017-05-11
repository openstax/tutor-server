class CourseMembership::Models::Teacher < Tutor::SubSystems::BaseModel

  belongs_to :role, subsystem: :entity, inverse_of: :teacher
  belongs_to :course, subsystem: :course_profile, inverse_of: :teachers

  validates :role,   presence: true, uniqueness: true
  validates :course, presence: true

  delegate :username, :first_name, :last_name, :full_name, :name, to: :role

end
