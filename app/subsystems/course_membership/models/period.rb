class CourseMembership::Models::Period < Tutor::SubSystems::BaseModel
  wrapped_by ::Period

  belongs_to :course, subsystem: :entity

  has_many :teachers, through: :course
  has_many :teacher_roles, through: :teachers, source: :role, class_name: 'Entity::Role'

  has_many :enrollments, dependent: :destroy
  has_many :students, through: :enrollments
  has_many :student_roles, through: :students, source: :role, class_name: 'Entity::Role'

  before_destroy :no_enrollments, prepend: true

  validates :course, presence: true
  validates :name, presence: true, uniqueness: { scope: :entity_course_id }

  default_scope { order(:name) }

  protected

  def no_enrollments
    return unless enrollments.any?
    errors.add(:students, 'must be moved to another period before this period can be deleted')
    false
  end
end
