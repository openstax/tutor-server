class CourseMembership::Models::EnrollmentChange < Tutor::SubSystems::BaseModel
  belongs_to :profile, subsystem: :user
  belongs_to :enrollment # from
  belongs_to :period     # to

  enum status: [ :pending, :succeeded, :failed ]

  validates :profile, presence: true
  validates :enrollment, uniqueness: { allow_nil: true }
  validates :period, presence: true
  validate :same_profile, :different_period

  def from_period
    enrollment.try(:period)
  end

  alias_method :to_period, :period

  protected

  def same_profile
    return if profile.nil? || enrollment.nil? || enrollment.student.role.profile == profile
    errors.add(:base, 'the given user does not match the given enrollment')
    false
  end

  def different_period
    return if enrollment.nil? || period.nil? || enrollment.period != period
    errors.add(:base, 'the given user is already enrolled in the given period')
    false
  end
end
