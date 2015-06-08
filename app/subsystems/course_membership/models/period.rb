class CourseMembership::Models::Period < Tutor::SubSystems::BaseModel
  wrapped_by ::Period

  belongs_to :course, subsystem: :entity
  has_many :teachers, through: :course
  has_many :teacher_roles, through: :teachers, source: :role, class_name: 'Entity::Role'

  has_many :students, dependent: :destroy
  has_many :student_roles, through: :students, source: :role, class_name: 'Entity::Role'

  before_destroy :no_students, prepend: true

  validates :course, presence: true
  validates :name, presence: true, uniqueness: { scope: :entity_course_id }

  protected

  def no_students
    return unless students.any?
    errors.add(:students, 'must be moved to another period before this period can be deleted')
    false
  end
end
