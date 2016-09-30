class CourseMembership::Models::EnrollmentChange < Tutor::SubSystems::BaseModel

  wrapped_by CourseMembership::Strategies::Direct::EnrollmentChange

  acts_as_paranoid

  belongs_to :profile, -> { with_deleted }, subsystem: :user
  belongs_to :enrollment, -> { with_deleted } # from
  belongs_to :period, -> { with_deleted }     # to
  belongs_to :conflicting_enrollment, -> { with_deleted },
                                      class_name: 'CourseMembership::Models::Enrollment'

  enum status: [ :pending, :approved, :rejected, :processed ]

  validates :profile, presence: true
  validates :period, presence: true
  validate :same_profile, :same_course, :course_not_ended,
           :different_period_unless_conflict, :valid_conflict

  def from_period
    enrollment.try!(:period)
  end

  def conflicting_period
    conflicting_enrollment.period unless conflicting_enrollment.nil? ||
                                         conflicting_enrollment.deleted? ||
                                         conflicting_enrollment.student.deleted?
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

  def different_period_unless_conflict
    return if enrollment.nil? || period.nil? || enrollment.period != period ||
              conflicting_enrollment.present?
    errors.add(:base, 'the given user is already enrolled in the given period')
    false
  end

  def valid_conflict
    return if conflicting_enrollment.nil? ||
              ( conflicting_enrollment.period.course.is_concept_coach &&
                ( profile.nil? || conflicting_enrollment.student.role.profile == profile ) &&
                ( period.nil? ||
                  ( period.course != conflicting_enrollment.period.course &&
                    period.course.is_concept_coach ) ) )
    errors.add(:conflicting_enrollment, 'is invalid')
    false
  end

end
