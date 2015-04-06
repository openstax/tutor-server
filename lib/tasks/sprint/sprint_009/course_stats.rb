module Sprint009
  class CourseStats

    lev_routine

    uses_routine Domain::GetUserCourseStats,
      translations: { outputs: { type: :verbatim } },
      as: :get_course_stats


    protected
    def exec(course:)
      run(:get_course_stats, user: nil, course: course)
    end
  end
end
