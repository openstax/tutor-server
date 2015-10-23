module CourseMembership
  class Period
    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer, error: StrategyError
    end

    def course
      verify_and_return @strategy.course, klass: Entity::Course, error: StrategyError
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

    def enrollment_code
      verify_and_return @strategy.enrollment_code, klass: String, error: StrategyError
    end

    def to_model
      @strategy.to_model
    end
  end
end
