class CourseMembership::Models::Period < Tutor::SubSystems::BaseModel
  acts_as_paranoid

  wrapped_by CourseMembership::Strategies::Direct::Period

  belongs_to :course, subsystem: :entity

  has_many :teachers, through: :course
  has_many :teacher_roles, through: :teachers, source: :role, class_name: 'Entity::Role'

  has_many :enrollments, dependent: :destroy
  has_many :latest_enrollments,
           -> { latest },
           class_name: '::CourseMembership::Models::Enrollment'
  has_many :active_enrollments,
           -> { latest.active },
           class_name: '::CourseMembership::Models::Enrollment'

  has_many :enrollment_changes, dependent: :destroy

  has_many :taskings, subsystem: :tasks, dependent: :nullify
  has_many :tasks, through: :taskings

  before_validation :generate_enrollment_code
  before_destroy :no_active_students, prepend: true

  validates :course, presence: true
  validates :name, presence: true, uniqueness: { scope: :entity_course_id }
  validates :enrollment_code, presence: true, uniqueness: true

  default_scope { order(:name) }

  def student_roles(include_inactive_students: false)
    target_enrollments = include_inactive_students ? latest_enrollments : active_enrollments
    target_enrollments.includes(student: :role).collect{ |en| en.student.role }
  end

  protected

  def no_active_students
    return unless enrollments.latest.active.exists?
    errors.add(:students, 'must be moved to another period before this period can be deleted')
    false
  end

  def generate_enrollment_code
    return true unless enrollment_code.blank?

    begin
      self.enrollment_code = Babbler.babble
    end while self.class.exists?(enrollment_code: self[:enrollment_code])
  end
end
