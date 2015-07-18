class CourseMembership::Models::Enrollment < Tutor::SubSystems::BaseModel
  belongs_to :period
  belongs_to :student

  validates :period, presence: true
  validates :student, presence: true

  default_scope -> { order(created_at: :asc) }

  scope :latest, -> {
    joins{CourseMembership::Models::Enrollment.unscoped.as(:same_student).on{
      (same_student.course_membership_student_id == ~course_membership_student_id) & \
      (same_student.created_at > ~created_at)
    }.outer}.where(same_student: {id: nil})
  }
end
