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

  has_many :research_cohort_members, class_name: '::Research::Models::CohortMember', inverse_of: :student
  has_many :research_cohorts, through: :research_cohort_members, source: :cohort

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
    # Give the student til midnight after configurable days from now
    course.time_zone.to_tz.now.midnight + 1.day - 1.second +
      Settings::Payments.student_grace_period_days.days
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
