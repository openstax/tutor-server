require './spec/support/setup_course_stats'

module Sprint009
  class CourseStats
    lev_routine delegates_to: SetupCourseStats
  end
end
