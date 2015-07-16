class CourseMembership::Models::Student < Tutor::SubSystems::BaseModel
  belongs_to :role, subsystem: :entity
  belongs_to :period

  has_one :course, through: :period, class_name: 'Entity::Course'

  validates :period, presence: true
  validates :role, presence: true, uniqueness: { scope: :course_membership_period_id }
  validates :deidentifier, uniqueness: true

  delegate :username, :first_name, :last_name, :full_name, :name, to: :role

  before_save :generate_deidentifier

  protected

  def generate_deidentifier
    begin
      deidentifier = SecureRandom.hex(4)
    end while CourseMembership::Models::Student.exists?(deidentifier: deidentifier)
    self.deidentifier ||= deidentifier
  end

end
