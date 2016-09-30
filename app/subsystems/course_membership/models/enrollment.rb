class CourseMembership::Models::Enrollment < Tutor::SubSystems::BaseModel

  acts_as_paranoid

  belongs_to :period, -> { with_deleted }
  belongs_to :student, -> { with_deleted }

  has_one :enrollment_change, -> { with_deleted }, dependent: :destroy

  validates :period, presence: true
  validates :student, presence: true
  validate :same_course

  default_scope -> { order(:created_at) }

  scope :latest, -> {
    joins{CourseMembership::Models::Enrollment.unscoped.as(:newer_enrollment).on{
      (newer_enrollment.course_membership_student_id == ~course_membership_student_id) & \
      (newer_enrollment.created_at > ~created_at)
    }.outer}.where(newer_enrollment: {id: nil})
  }

  protected

  def same_course
    return if student.nil? || period.nil? || student.course == period.course
    errors.add(:base, 'must have a student and a period that belong to the same course')
    false
  end

end
