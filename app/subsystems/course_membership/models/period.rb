class CourseMembership::Models::Period < Tutor::SubSystems::BaseModel
  wrapped_by ::Period

  belongs_to :course, subsystem: :entity

  has_many :teachers, through: :course
  has_many :teacher_roles, through: :teachers, source: :role, class_name: 'Entity::Role'

  has_many :enrollments, dependent: :destroy

  before_destroy :no_active_students, prepend: true

  validates :course, presence: true
  validates :name, presence: true, uniqueness: { scope: :entity_course_id }

  default_scope { order(:name) }

  def student_roles
    enrollments.latest.active.includes(student: :role).collect{ |en| en.student.role }
  end

  protected

  def no_active_students
    return unless enrollments.latest.active.exists?
    errors.add(:students, 'must be moved to another period before this period can be deleted')
    false
  end
end
