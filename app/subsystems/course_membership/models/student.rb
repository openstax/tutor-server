class CourseMembership::Models::Student < ApplicationRecord

  acts_as_paranoid column: :dropped_at, without_default_scope: true

  REFUND_PERIOD = 14.days # TODO make this configurable

  auto_uuid

  belongs_to :role,   subsystem: :entity, inverse_of: :student
  belongs_to :course, subsystem: :course_profile, inverse_of: :students
  belongs_to :period, inverse_of: :students

  has_many :enrollments, inverse_of: :student
  has_one :latest_enrollment, -> { latest }, class_name: '::CourseMembership::Models::Enrollment'
  has_many :surveys, subsystem: :research, inverse_of: :student

  before_validation :init_first_paid_at

  validates :role, presence: true, uniqueness: true
  validates :course, :period, presence: true

  before_save :init_payment_due_at

  delegate :username, :first_name, :last_name, :full_name, :name, to: :role

  def dropped?
    deleted?
  end

  def is_refund_allowed
    is_paid ? first_paid_at + REFUND_PERIOD > Time.current : false
  end

  def new_payment_due_at
    tz = course.time_zone.to_tz

    # Give the student til 11:59:59 PM in the course's timezone
    # after Settings::Payments.student_grace_period_days days from now
    [ tz.now, course.starts_at.in_time_zone(tz) ].max.midnight +
      Settings::Payments.student_grace_period_days.days + 1.day - 1.second
  end

  protected

  def init_first_paid_at
    # Better for this value to be set using actual payment time from Payments,
    # but this is better than nothing
    self.first_paid_at ||= Time.current if is_paid
  end

  def init_payment_due_at
    self.payment_due_at ||= new_payment_due_at
  end

end
