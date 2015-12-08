module CourseMembership
  class GetCoursePeriods
    lev_routine outputs: { periods: :_self },
                uses: { name: CourseMembership::IsCourseTeacher, as: :is_teacher }

    protected

    def exec(course:, roles: [])
      roles = [roles].flatten

      models = roles.any? ? periods_for_roles(course, roles) : course.periods
      set(periods: models.collect do |model|
        strategy = CourseMembership::Strategies::Direct::Period.new(model)
        CourseMembership::Period.new(strategy: strategy)
      end)
    end

    def periods_for_roles(course, roles)
      is_teacher = run(:is_teacher, course: course, roles: roles)
      role_periods = is_teacher ? course.periods : roles.collect{ |rr| rr.student.try(:period) }
      course.periods & role_periods
    end
  end
end
