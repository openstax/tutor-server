module CourseMembership
  class Period
    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer, error: StrategyError
    end

    def course
      verify_and_return @strategy.course, klass: CourseProfile::Models::Course, error: StrategyError
    end

    def name
      verify_and_return @strategy.name, klass: String, error: StrategyError
    end

    def student_roles(include_inactive_students: false)
      verify_and_return @strategy.student_roles(
        include_inactive_students: include_inactive_students
      ), klass: Entity::Role, error: StrategyError
    end

    def teacher_roles
      verify_and_return @strategy.teacher_roles, klass: Entity::Role, error: StrategyError
    end

    def teacher_student_role
      verify_and_return @strategy.teacher_student_role, klass: Entity::Role, error: StrategyError
    end

    def entity_teacher_student_role_id
      verify_and_return @strategy.entity_teacher_student_role_id, klass: Integer,
                                                                  error: StrategyError
    end

    def enrollment_code
      verify_and_return @strategy.enrollment_code, klass: String, error: StrategyError
    end

    def default_open_time
      verify_and_return @strategy.default_open_time, klass: String,
                                                     error: StrategyError,
                                                     allow_nil: true
    end

    def default_due_time
      verify_and_return @strategy.default_due_time, klass: String,
                                                     error: StrategyError,
                                                     allow_nil: true
    end

    def deleted?
      !!@strategy.deleted?
    end

    def deleted_at
      @strategy.deleted_at
    end

    def enrollment_code_for_url
      verify_and_return @strategy.enrollment_code_for_url, klass: String, error: StrategyError
    end

    def to_model
      @strategy.to_model
    end
  end
end
