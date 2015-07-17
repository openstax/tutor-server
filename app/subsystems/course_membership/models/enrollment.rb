class CourseMembership::Models::Enrollment < Tutor::SubSystems::BaseModel
  belongs_to :period
  belongs_to :student

  validates :period, presence: true
  validates :student, presence: true, uniqueness: { scope: :course_membership_period_id }
end
