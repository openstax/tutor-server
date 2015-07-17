class CourseMembership::Models::Enrollment < Tutor::SubSystems::BaseModel
  belongs_to :period
  belongs_to :student

  validates :period, presence: true
  validates :student, presence: true

  scope :active, -> {
    joins{CourseMembership::Models::Enrollment.unscoped.as(:same_student).on{
      (same_student.course_membership_student_id == ~course_membership_student_id) & \
      (same_student.created_at > ~created_at)
    }.outer}.where(inactive_at: nil, same_student: {id: nil})
  }

  def inactivate(time = Time.now)
    self.inactive_at = time
    self
  end
end
