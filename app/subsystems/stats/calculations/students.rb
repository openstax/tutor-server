class Stats::Calculations::Students
  lev_routine

  protected

  def exec(interval:)
    interval.stats['new_enrollments'] = CourseMembership::Models::Student
      .where(:created_at => interval.range)
      .count

    st = CourseMembership::Models::Student.arel_table
    interval.stats['active_students'] = CourseMembership::Models::Student
      .where(st[:created_at].lteq(interval.ends_at))
      .where(course_profile_course_id: interval.courses.active.map(&:id))
      .count
  end

end
