class Stats::Calculations::Courses
  lev_routine

  protected

  def exec(interval:)
    co = CourseProfile::Models::Course.arel_table

    interval.courses.active = CourseProfile::Models::Course
      .where(is_test: false, is_preview: false)
      .where(
        co[:starts_at].lteq(interval.starts_at),
        co[:ends_at].gteq(interval.ends_at),
      )

    interval.stats['active_courses'] = interval.courses.active.dup.count

    st = CourseMembership::Models::Student.arel_table
    interval.courses.populated = interval.courses.active
      .select(co[Arel.star], st[:id].count)
      .joins(:students)
      .group(co[:id])
      .having(st[:id].count.gteq(3))

    interval.stats['active_populated_courses'] = interval.courses.populated.dup.length
  end

end
