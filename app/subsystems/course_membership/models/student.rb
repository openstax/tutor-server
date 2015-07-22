class CourseMembership::Models::Student < Tutor::SubSystems::BaseModel
  belongs_to :course, subsystem: :entity
  belongs_to :role, subsystem: :entity

  has_many :enrollments, dependent: :destroy

  validates :course, presence: true
  validates :role, presence: true, uniqueness: { scope: :entity_course_id }
  validates :deidentifier, uniqueness: true

  before_save :generate_deidentifier

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

  protected

  def generate_deidentifier
    begin
      deidentifier = SecureRandom.hex(4)
    end while CourseMembership::Models::Student.exists?(deidentifier: deidentifier)
    self.deidentifier ||= deidentifier
  end
end
