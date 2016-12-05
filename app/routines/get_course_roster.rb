class GetCourseRoster
  lev_routine express_output: :roster

  uses_routine GetCourseTeachers

  protected

  def exec(course:)
    students = course.students.with_deleted.includes(:enrollments, role: { profile: :account })

    outputs.roster = {
      teach_url: UrlGenerator.teach_course_url(course.teach_token),
      teachers: run(GetCourseTeachers,course).outputs.teachers,
      students: students.map do |student|
        Hashie::Mash.new({
          id: student.id,
          first_name: student.first_name,
          last_name: student.last_name,
          name: student.name,
          course_membership_period_id: student.course_membership_period_id,
          entity_role_id: student.entity_role_id,
          username: student.username,
          student_identifier: student.student_identifier,
          deleted?: student.deleted?
        })
      end
    }
  end
end
