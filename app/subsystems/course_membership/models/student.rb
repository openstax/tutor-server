class CourseMembership::Models::Student < Tutor::SubSystems::BaseModel
  belongs_to :period
  has_one :course, through: :period, class_name: 'Entity::Course'

  belongs_to :role, subsystem: :entity

  validates :period, presence: true
  validates :role, presence: true, uniqueness: { scope: :course_membership_period_id }
end
