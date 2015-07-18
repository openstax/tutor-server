class CourseMembership::Models::Period < Tutor::SubSystems::BaseModel
  wrapped_by ::Period

  belongs_to :course, subsystem: :entity

  has_many :teachers, through: :course
  has_many :teacher_roles, through: :teachers, source: :role, class_name: 'Entity::Role'

  has_many :enrollments, dependent: :destroy
  has_many :latest_enrollments, -> { latest }, class_name: 'CourseMembership::Models::Enrollment'

  has_many :students, through: :latest_enrollments
  has_many :active_students, -> { active }, class_name: 'CourseMembership::Models::Student',
                                            through: :latest_enrollments

  has_many :student_roles, through: :active_students, source: :role, class_name: 'Entity::Role'

  before_destroy :no_active_students, prepend: true

  validates :course, presence: true
  validates :name, presence: true, uniqueness: { scope: :entity_course_id }

  default_scope { order(:name) }

  protected

  def no_active_students
    return unless active_students.exists?
    errors.add(:students, 'must be moved to another period before this period can be deleted')
    false
  end
end
