module CourseMembership
  class GetCoursePeriods
    lev_routine express_output: :periods

    uses_routine CourseMembership::IsCourseTeacher, as: :is_teacher

    protected

    def exec(course:, roles: [], include_archived: false)
      roles = [roles].flatten

      all_periods = include_archived ? course.periods.with_deleted : course.periods
      models = roles.any? ? periods_for_roles(course, all_periods, roles) : all_periods

      outputs[:periods] = models.map do |model|
        strategy = CourseMembership::Strategies::Direct::Period.new(model)
        CourseMembership::Period.new(strategy: strategy)
      end
    end

    def periods_for_roles(course, all_periods, roles)
      is_teacher = run(:is_teacher, course: course, roles: roles).outputs.is_course_teacher
      return all_periods if is_teacher

      role_periods = roles.map { |role| role.student.try!(:period) }
      all_periods & role_periods
    end
  end
end
