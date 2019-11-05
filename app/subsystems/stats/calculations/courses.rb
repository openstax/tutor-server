class Stats::Calculations::Courses
  lev_routine

  protected

  def exec(stats:, date_range:)
    co = CourseProfile::Models::Course.arel_table

    outputs.active_courses = CourseProfile::Models::Course
      .where(is_test: false, is_preview: false)
      .where(
        co[:starts_at].lteq(date_range.end),
        co[:ends_at].gteq(date_range.first),
      )
    outputs.num_active_courses = outputs.active_courses.dup.count

    st = CourseMembership::Models::Student.arel_table
    outputs.active_populated_courses = CourseProfile::Models::Course
      .select(co[Arel.star], st[:id].count)
      .joins(:students)
      .group(co[:id])
      .having(st[:id].count.gteq(3))

    outputs.num_active_populated_courses = outputs.active_populated_courses.dup.length
  end

end
