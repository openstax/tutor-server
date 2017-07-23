class CourseMembership::Models::Student < Tutor::SubSystems::BaseModel

  REFUND_PERIOD = 14.days # TODO make this configurable

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

  after_validation :init_payment_due_at

  delegate :username, :first_name, :last_name, :full_name, :name, to: :role
  delegate :period, :course_membership_period_id, to: :latest_enrollment, allow_nil: true

  def is_refund_allowed
    is_paid ? first_paid_at + REFUND_PERIOD > Time.now : false
  end

  def new_payment_due_at
    # Give the student til midnight after configurable days from now
    course.time_zone.to_tz.now.midnight + 1.day - 1.second +
      Settings::Payments.student_grace_period_days.days
  end

  protected

  def init_first_paid_at
    # Better for this value to be set using actual payment time from Payments,
    # but this is better than nothing
    self.first_paid_at ||= Time.now if is_paid
  end

  def init_payment_due_at
    self.payment_due_at ||= new_payment_due_at
  end

end
