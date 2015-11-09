class GetCourseRoster
  lev_routine express_output: :roster

  protected

  def exec(course:)
    students = course.students.includes(:enrollments, role: { profile: :account })

    outputs.roster = {
      teacher_join_url: join_course_url(course.teacher_join_token),
      students: students.collect do |student|
        Hashie::Mash.new({
          id: student.id,
          first_name: student.first_name,
          last_name: student.last_name,
          name: student.name,
          course_membership_period_id: student.course_membership_period_id,
          entity_role_id: student.entity_role_id,
          username: student.username,
          deidentifier: student.deidentifier,
          :active? => student.active?
        })
      end
    }
  end
end
