class CourseMembership::Models::Student < Tutor::SubSystems::BaseModel

  acts_as_paranoid

  auto_uuid

  belongs_to :course, subsystem: :course_profile, inverse_of: :students
  belongs_to :role, subsystem: :entity, inverse_of: :student

  has_many :enrollments, -> { with_deleted }, dependent: :destroy, inverse_of: :student
  has_one :latest_enrollment, -> { latest.with_deleted },
                              class_name: '::CourseMembership::Models::Enrollment'

  before_validation :init_first_paid_at

  validates :course, presence: true
  validates :role, presence: true, uniqueness: true

  delegate :username, :first_name, :last_name, :full_name, :name, to: :role
  delegate :period, :course_membership_period_id, to: :latest_enrollment, allow_nil: true

  def is_refund_allowed
    is_paid ? first_paid_at + 14.days > Time.now : false # TODO make this configurable
  end

  protected

  def init_first_paid_at
    # Better for this value to be set using actual payment time from Payments,
    # but this is better than nothing
    self.first_paid_at ||= Time.now if is_paid
  end

end
