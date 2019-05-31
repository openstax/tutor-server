class CourseMembership::Models::EnrollmentChange < IndestructibleRecord

  wrapped_by CourseMembership::Strategies::Direct::EnrollmentChange

  belongs_to :profile, subsystem: :user
  belongs_to :period, inverse_of: :enrollment_changes                    # to
  belongs_to :enrollment, inverse_of: :enrollment_change, optional: true # from
  belongs_to :conflicting_enrollment, class_name: 'CourseMembership::Models::Enrollment',
                                      optional: true

  enum status: [ :pending, :approved, :rejected, :processed ]

  validate :same_profile, :same_course, :course_not_ended,
           :different_period_unless_conflict, :valid_conflict

  def from_period
    enrollment.try!(:period)
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
    throw :abort
  end

  def same_course
    return if enrollment.nil? || period.nil? || period.course == enrollment.period.course
    errors.add(:base, 'the given periods must belong to the same course')
    throw :abort
  end

  def course_not_ended
    return if period.nil? || !period.course.ended?
    errors.add(:period, 'belongs to a course that has already ended')
    throw :abort
  end

  def different_period_unless_conflict
    return if enrollment.nil? || period.nil? || enrollment.period != period ||
              conflicting_enrollment.present?
    errors.add(:base, 'the given user is already enrolled in the given period')
    throw :abort
  end

  def valid_conflict
    return if conflicting_enrollment.nil? ||
              ( conflicting_enrollment.period.course.is_concept_coach &&
                ( profile.nil? || conflicting_enrollment.student.role.profile == profile ) &&
                ( period.nil? ||
                  ( period.course != conflicting_enrollment.period.course &&
                    period.course.is_concept_coach ) ) )
    errors.add(:conflicting_enrollment, 'is invalid')
    throw :abort
  end

end
