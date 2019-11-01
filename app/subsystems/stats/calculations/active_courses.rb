class Stats::Calculations::ActiveCourses
  lev_routine

  protected

  def exec(courses: nil, date_range:)
    outputs.active_courses = CourseProfile::Models::Course.where(
       'is_test=\'f\' and is_preview=\'f\' and starts_at <= :ends_at and ends_at >= :starts_at',
      { starts_at: date_range.first, ends_at: date_range.last }
    )
    outputs.num_active_courses = outputs.active_courses.dup.count
  end

end
