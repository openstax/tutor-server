class CourseMembership::Models::Student < Tutor::SubSystems::BaseModel
  belongs_to :course, subsystem: :entity
  belongs_to :role, subsystem: :entity

  has_many :enrollments, dependent: :destroy
  has_one :active_enrollment, -> { latest }, class_name: 'CourseMembership::Models::Enrollment'
  has_one :period, through: :active_enrollment

  validates :course, presence: true
  validates :role, presence: true, uniqueness: { scope: :entity_course_id }
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
