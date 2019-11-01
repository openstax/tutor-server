class Stats::Calculations::ActiveCourses
  lev_routine

  protected

  def exec(courses: nil, date_range:)
    co = CourseProfile::Models::Course.arel_table
    outputs.active_courses = CourseProfile::Models::Course
      .where(is_test: false, is_preview: false)
      .where(
        co[:starts_at].lteq(date_range.end),
        co[:ends_at].gteq(date_range.first),
      )

    outputs.num_active_courses = outputs.active_courses.dup.count
  end

end
