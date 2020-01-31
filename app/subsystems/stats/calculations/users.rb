class Stats::Calculations::Users
  lev_routine

  protected

  def exec(interval:)

    s = CourseMembership::Models::Student
    t = CourseMembership::Models::Teacher

    interval.stats['new_students'] = s.where(:created_at => interval.range).count
    interval.stats['new_instructors'] = t.where(:created_at => interval.range).count

    interval.stats['active_students'] = s
      .where(s.arel_table[:created_at].lteq(interval.ends_at))
      .where(dropped_at: nil, course_profile_course_id: interval.courses.active.map(&:id))
      .count

    interval.stats['active_instructors'] = t
      .where(t.arel_table[:created_at].lteq(interval.ends_at))
      .where(deleted_at: nil, course_profile_course_id: interval.courses.active.map(&:id))
      .count

  end

end
