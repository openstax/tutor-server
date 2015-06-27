class CourseMembership::Models::Student < Tutor::SubSystems::BaseModel
  belongs_to :role, subsystem: :entity
  belongs_to :period

  has_one :course, through: :period, class_name: 'Entity::Course'

  validates :period, presence: true
  validates :role, presence: true, uniqueness: { scope: :course_membership_period_id }

  delegate :first_name, :last_name, :full_name, to: :role
end
