module CourseMembership
  class GetCoursePeriods
    lev_routine express_output: :periods

    uses_routine CourseMembership::IsCourseTeacher, as: :is_teacher

    protected

    def exec(course:, roles: [], include_archived_periods: false)
      roles = [roles].flatten

      all_periods = include_archived_periods ? course.periods : course.periods.without_deleted
      outputs.periods = roles.any? ? periods_for_roles(course, all_periods, roles) : all_periods
    end

    def periods_for_roles(course, all_periods, roles)
      is_teacher = run(:is_teacher, course: course, roles: roles).outputs.is_course_teacher
      return all_periods if is_teacher

      role_periods = roles.map { |role| role.student&.period }
      all_periods & role_periods
    end
  end
end
