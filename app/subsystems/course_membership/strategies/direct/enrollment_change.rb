class CourseMembership::Strategies::Direct::EnrollmentChange < Entity

  wraps CourseMembership::Models::EnrollmentChange

  exposes :profile, :from_period, :to_period, :conflicting_period,
          :student_identifier, :status, :pending?, :approved?, :rejected?, :processed?,
          :requires_enrollee_approval, :enrollee_approved_at

  def user
    ::User::User.new(strategy: profile)
  end

  alias_method :from_period_strategy, :from_period
  def from_period
    strategy = from_period_strategy
    strategy.nil? ? nil : ::CourseMembership::Period.new(strategy: strategy)
  end

  alias_method :to_period_strategy, :to_period
  def to_period
    ::CourseMembership::Period.new(strategy: to_period_strategy)
  end

  alias_method :conflicting_period_strategy, :conflicting_period
  def conflicting_period
    strategy = conflicting_period_strategy
    strategy.nil? ? nil : ::CourseMembership::Period.new(strategy: strategy)
  end

  alias_method :string_status, :status
  def status
    string_status.to_sym
  end

  def to_model
    repository
  end

end
