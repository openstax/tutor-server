module CourseMembership
  class EnrollmentChange
    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer, error: StrategyError
    end

    def user
      verify_and_return @strategy.user, klass: ::User::User, error: StrategyError
    end

    def from_period
      verify_and_return @strategy.from_period, klass: CourseMembership::Period,
                                               error: StrategyError, allow_nil: true
    end

    def to_period
      verify_and_return @strategy.to_period, klass: CourseMembership::Period,
                                             error: StrategyError
    end

    def conflicting_enrollment
      verify_and_return @strategy.conflicting_enrollment,
                        klass: CourseMembership::Models::Enrollment,
                        error: StrategyError,
                        allow_nil: true
    end

    def student_identifier
      verify_and_return @strategy.student_identifier, klass: String,
                                                      error: StrategyError, allow_nil: true
    end

    def status
      verify_and_return @strategy.status, klass: Symbol, error: StrategyError
    end

    def pending?
      !!@strategy.pending?
    end

    def approved?
      !!@strategy.approved?
    end

    def rejected?
      !!@strategy.rejected?
    end

    def processed?
      !!@strategy.processed?
    end

    def requires_enrollee_approval?
      !!@strategy.requires_enrollee_approval
    end

    def enrollee_approved_at
      verify_and_return @strategy.enrollee_approved_at, klass: Time,
                                                        error: StrategyError, allow_nil: true
    end

    def to_model
      @strategy.to_model
    end
  end
end
