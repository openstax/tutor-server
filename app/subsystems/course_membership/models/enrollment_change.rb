class CourseMembership::Models::EnrollmentChange < Tutor::SubSystems::BaseModel
  wrapped_by CourseMembership::Strategies::Direct::EnrollmentChange

  acts_as_paranoid

  belongs_to :profile, subsystem: :user
  belongs_to :enrollment # from
  belongs_to :period     # to

  enum status: [ :pending, :approved, :rejected, :processed ]

  validates :profile, presence: true
  validates :period, presence: true
  validate :same_profile, :different_period, :same_book

  def from_period
    enrollment.try(:period)
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

  def different_period
    return if enrollment.nil? || period.nil? || enrollment.period != period
    errors.add(:base, 'the given user is already enrolled in the given period')
    false
  end

  def same_book
    return if enrollment.nil? || period.nil?
    course_a = period.course
    course_b = enrollment.period.course
    return if course_a == course_b
    ecosystem_a = GetCourseEcosystem[course: course_a]
    ecosystem_b = GetCourseEcosystem[course: course_b]
    uuid_a = ecosystem_a.nil? ? nil : ecosystem_a.books.first.uuid
    uuid_b = ecosystem_b.nil? ? nil : ecosystem_b.books.first.uuid
    return if uuid_a == uuid_b
    errors.add(:base, 'the given periods must belong to courses with the same book')
    false
  end
end
