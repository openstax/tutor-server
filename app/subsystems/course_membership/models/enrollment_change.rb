class CourseMembership::Models::EnrollmentChange < IndestructibleRecord

  wrapped_by CourseMembership::Strategies::Direct::EnrollmentChange

  belongs_to :profile, subsystem: :user
  belongs_to :enrollment, inverse_of: :enrollment_change # from
  belongs_to :period                                     # to
  belongs_to :conflicting_enrollment, class_name: 'CourseMembership::Models::Enrollment'

  enum status: [ :pending, :approved, :rejected, :processed ]

  validates :profile, presence: true
  validates :period, presence: true
  validate :same_profile, :same_course, :course_not_ended, :different_period

  def from_period
    enrollment.try!(:period)
  end

  def conflicting_period
    conflicting_enrollment.period unless conflicting_enrollment.nil? ||
                                         conflicting_enrollment.period.archived? ||
                                         conflicting_enrollment.student.dropped?
  end

  alias_method :to_period, :period

  def student_identifier
    enrollment.nil? ? nil : enrollment.student.student_identifier
  end

  def approve_by(user, time = Time.current)
    # User is ignored for now
    self.enrollee_approved_at = time
    self.status = :approved
    self
  end

  def process
    self.status = :processed
    self
  end

  protected

  def same_profile
    return if enrollment.nil? || profile.nil? || enrollment.student.role.profile == profile
    errors.add(:base, 'the given user does not match the given enrollment')
    false
  end

  def same_course
    return if enrollment.nil? || period.nil? || period.course == enrollment.period.course
    errors.add(:base, 'the given periods must belong to the same course')
    false
  end

  def course_not_ended
    return if period.nil? || !period.course.ended?
    errors.add(:period, 'belongs to a course that has already ended')
    false
  end

  def different_period
    return if enrollment.nil? || period.nil? || enrollment.period != period
    errors.add(:base, 'the given user is already enrolled in the given period')
    false
  end

end
