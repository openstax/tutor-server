class CourseMembership::Models::Enrollment < Tutor::SubSystems::BaseModel
  belongs_to :period
  belongs_to :student

  validates :period, presence: true
  validates :student, presence: true

  default_scope -> { order(created_at: :asc) }

  scope :latest, -> {
    joins{CourseMembership::Models::Enrollment.unscoped.as(:newer_enrollment).on{
      (newer_enrollment.course_membership_student_id == ~course_membership_student_id) & \
      (newer_enrollment.created_at > ~created_at)
    }.outer}.where(newer_enrollment: {id: nil})
  }

  scope :active, -> {
    joins(:student).where(student: {inactive_at: nil})
  }
end
