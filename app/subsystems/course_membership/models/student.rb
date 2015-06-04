class CourseMembership::Models::Student < Tutor::SubSystems::BaseModel
  wrapped_by ::Student

  belongs_to :period
  belongs_to :role, subsystem: :entity

  has_one :course, through: :period

  validates :period, presence: true
  validates :role, presence: true, uniqueness: { scope: :course_membership_period_id }
end
