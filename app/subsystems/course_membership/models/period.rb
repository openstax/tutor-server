class CourseMembership::Models::Period < ApplicationRecord

  acts_as_paranoid column: :archived_at, without_default_scope: true

  include DefaultTimeValidations

  wrapped_by CourseMembership::Strategies::Direct::Period

  auto_uuid

  belongs_to :course, subsystem: :course_profile, inverse_of: :periods

  belongs_to :teacher_student_role, subsystem: :entity, class_name: 'Entity::Role'

  has_many :teachers, through: :course
  has_many :teacher_roles, through: :teachers, source: :role, class_name: 'Entity::Role'

  has_many :enrollments, inverse_of: :period
  has_many :latest_enrollments, -> { latest }, class_name: '::CourseMembership::Models::Enrollment'

  has_many :enrollment_changes, inverse_of: :period

  has_many :students, through: :latest_enrollments

  has_many :taskings, subsystem: :tasks, inverse_of: :period
  has_many :tasks, through: :taskings
  has_many :tasking_plans, as: :target, class_name: 'Tasks::Models::TaskingPlan'
  unique_token :enrollment_code, mode: :random_number, length: 6

  validates :course, presence: true
  validates :teacher_student_role, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: { scope: :course_profile_course_id,
                                                 conditions: -> { where(archived_at: nil) } }
  validates :enrollment_code, format: { with: /\A[a-zA-Z0-9 ]+\z/ }

  validate :default_times_have_good_values

  before_validation :build_teacher_student_role, on: :create

  default_scope { order(:name) }

  def archived?
    deleted?
  end

  def student_roles(include_dropped_students: false)
    students = latest_enrollments.preload(student: :role).map(&:student)
    students = students.reject(&:dropped?) unless include_dropped_students
    students.map(&:role)
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

  def assignments_count
    tasking_plans
      .joins(:task_plan)
      .where { task_plan.first_published_at != nil }
      .count
  end

  protected

  def build_teacher_student_role
    self.teacher_student_role ||= Entity::Role.new(role_type: :teacher_student)
  end

end
