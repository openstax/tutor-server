class Stats::Calculations::Users
  lev_routine

  protected

  def exec(interval:)
    interval.stats['new_enrollments'] = CourseMembership::Models::Student
      .where(:created_at => interval.range)
      .count

    s = CourseMembership::Models::Student
    interval.stats['active_students'] = s
      .where(s.arel_table[:created_at].lteq(interval.ends_at))
      .where(course_profile_course_id: interval.courses.active.map(&:id))
      .count

    t = CourseMembership::Models::Teacher
    interval.stats['active_instructors'] = t
      .where(t.arel_table[:created_at].lteq(interval.ends_at))
      .where(course_profile_course_id: interval.courses.active.map(&:id))
      .count

  end

end
