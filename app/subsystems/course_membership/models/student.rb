class CourseMembership::Models::Student < Tutor::SubSystems::BaseModel

  acts_as_paranoid

  auto_uuid

  belongs_to :course, subsystem: :course_profile, inverse_of: :students
  belongs_to :role, subsystem: :entity, inverse_of: :student

  has_many :enrollments, -> { with_deleted }, dependent: :destroy, inverse_of: :student
  has_one :latest_enrollment, -> { with_deleted.latest },
                              class_name: '::CourseMembership::Models::Enrollment'

  validates :course, presence: true
  validates :role, presence: true, uniqueness: true

  delegate :username, :first_name, :last_name, :full_name, :name, to: :role
  delegate :period, :course_membership_period_id, to: :latest_enrollment, allow_nil: true


end
