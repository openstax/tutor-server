class CourseMembership::Models::Student < Tutor::SubSystems::BaseModel
  belongs_to :course, subsystem: :entity
  belongs_to :role, subsystem: :entity

  has_many :enrollments, dependent: :destroy

  validates :course, presence: true
  validates :role, presence: true, uniqueness: true
  validates :deidentifier, uniqueness: true
  validates :student_identifier, uniqueness: { scope: :course, allow_nil: true }

  unique_token :deidentifier, mode: { hex: { length: 4 } }

  delegate :username, :first_name, :last_name, :full_name, :name, to: :role
  delegate :period, :course_membership_period_id, to: :latest_enrollment

  scope :active, -> { where(inactive_at: nil) }

  def active?
    inactive_at.nil?
  end

  def inactivate(time = Time.now)
    self.inactive_at = time
    self
  end

  def activate
    self.inactive_at = nil
    self
  end

  def latest_enrollment
    enrollments.last
  end
end
