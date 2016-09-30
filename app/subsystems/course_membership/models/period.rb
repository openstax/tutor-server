class CourseMembership::Models::Period < Tutor::SubSystems::BaseModel

  include DefaultTimeValidations

  acts_as_paranoid

  wrapped_by CourseMembership::Strategies::Direct::Period

  auto_uuid

  belongs_to :course, subsystem: :course_profile

  # Roles don't have soft-delete so we don't destroy them when the period is archived
  belongs_to :teacher_student_role, subsystem: :entity, class_name: 'Entity::Role'

  has_many :teachers, through: :course
  has_many :teacher_roles, through: :teachers, source: :role, class_name: 'Entity::Role'

  has_many :enrollments, dependent: :destroy
  has_many :latest_enrollments, -> { latest }, class_name: '::CourseMembership::Models::Enrollment'
  has_many :latest_enrollments_with_deleted, -> { latest.with_deleted },
                                                class_name: '::CourseMembership::Models::Enrollment'

  has_many :enrollment_changes, dependent: :destroy

  has_many :taskings, subsystem: :tasks
  has_many :tasks, through: :taskings

  unique_token :enrollment_code, mode: :random_number, length: 6

  validates :course, presence: true
  validates :teacher_student_role, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: { scope: :course_profile_course_id,
                                                 conditions: -> { where(deleted_at: nil) } }
  validates :enrollment_code, format: { with: /\A[a-zA-Z0-9 ]+\z/ }

  validate :default_times_have_good_values

  before_validation :build_teacher_student_role, on: :create

  default_scope { order(:name) }

  def student_roles(include_inactive_students: false)
    target_enrollments = include_inactive_students ?
                           latest_enrollments.with_deleted : latest_enrollments
    target_enrollments.preload(student: :role).map{ |en| en.student.role }
  end

  def default_open_time
    read_attribute(:default_open_time) || Settings::Db.store[:default_open_time]
  end

  def default_due_time
    read_attribute(:default_due_time) || Settings::Db.store[:default_due_time]
  end

  def enrollment_code_for_url
    enrollment_code.gsub(/ /,'-')
  end

  protected

  def build_teacher_student_role
    self.teacher_student_role ||= Entity::Role.new(role_type: :teacher_student)
  end

end
