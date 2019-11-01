class Stats::Calculations::ActiveStudents
  lev_routine

  protected

  def exec(courses:, date_range:)
    outputs.num_new_enrollments = CourseMembership::Models::Student
      .where(:created_at => date_range)
      .count

    t = CourseMembership::Models::Student.table_name
    outputs.num_active_students = CourseMembership::Models::Student
      .where("#{t}.created_at <= :ends_at", { ends_at: date_range.last })
      .where(course_profile_course_id: courses.map(&:id))
      .count
  end

end
