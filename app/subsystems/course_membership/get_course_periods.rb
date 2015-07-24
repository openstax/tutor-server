module CourseMembership
  class GetCoursePeriods
    lev_routine express_output: :periods

    uses_routine CourseMembership::IsCourseTeacher, as: :is_teacher

    protected

    def exec(course:, roles: [])
      roles = [roles].flatten

      outputs[:periods] = if roles.any?
                            periods_for_roles(course, roles)
                          else
                            Entity::Relation.new(course.periods)
                          end
    end

    private

    def periods_for_roles(course, roles)
      is_teacher = run(:is_teacher, course: course, roles: roles).outputs.is_course_teacher
      role_periods = is_teacher ? course.periods : roles.collect{ |rr| rr.student.try(:period) }
      course.periods & role_periods
    end
  end
end
