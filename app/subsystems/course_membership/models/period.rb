class CourseMembership::Models::Period < ApplicationRecord

  acts_as_paranoid column: :archived_at, without_default_scope: true

  wrapped_by CourseMembership::Strategies::Direct::Period

  auto_uuid

  belongs_to :course, subsystem: :course_profile, inverse_of: :periods

  has_many :teachers, through: :course
  has_many :teacher_roles, through: :teachers, source: :role, class_name: 'Entity::Role'

  has_many :enrollments, inverse_of: :period
  has_many :latest_enrollments, -> { latest }, class_name: '::CourseMembership::Models::Enrollment'

  has_many :enrollment_changes, inverse_of: :period

  has_many :students, inverse_of: :period

  has_many :teacher_students, inverse_of: :period
  has_many :teacher_student_roles, through: :teacher_students,
                                   source: :role,
                                   class_name: 'Entity::Role'

  has_many :taskings, subsystem: :tasks, inverse_of: :period
  has_many :tasks, through: :taskings
  has_many :tasking_plans, as: :target, class_name: 'Tasks::Models::TaskingPlan'
  unique_token :enrollment_code, mode: :random_number, length: 6

  validates :name, presence: true, uniqueness: { scope: :course_profile_course_id,
                                                 conditions: -> { where(archived_at: nil) } }
  validates :enrollment_code, format: { with: /\A[a-zA-Z0-9 ]+\z/ }

  default_scope { order(:name) }

  def archived?
    deleted?
  end

  def student_roles(include_dropped_students: false)
    st = students.preload(:role)
    st = st.reject(&:dropped?) unless include_dropped_students
    st.map(&:role)
  end

  def enrollment_code_for_url
    enrollment_code.gsub(/ /,'-')
  end

  def assignments_count
    tasking_plans
      .joins(:task_plan)
      .where.not(task_plan: { first_published_at: nil })
      .count
  end

  def num_enrolled_students
    students.loaded? ? students.to_a.count { |student| !student.dropped? } :
                       students.without_deleted.count
  end

end
