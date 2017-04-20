class Entity::Role < Tutor::SubSystems::BaseModel
  enum role_type: [:unassigned, :default, :teacher, :student, :teacher_student]

  has_many :taskings, -> { with_deleted }, subsystem: :tasks, dependent: :destroy

  has_one :student, -> { with_deleted }, dependent: :destroy, subsystem: :course_membership
  has_one :teacher, dependent: :destroy, subsystem: :course_membership

  has_one :role_user, dependent: :destroy, subsystem: :role
  has_one :profile, through: :role_user, subsystem: :user

  delegate :username, :first_name, :last_name, :full_name, :name, to: :profile, allow_nil: true

  unique_token :research_identifier, mode: :hex, length: 4

  def latest_enrollment_at
    student.try!(:latest_enrollment).try!(:created_at)
  end
end
