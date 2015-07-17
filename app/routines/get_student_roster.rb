class GetStudentRoster
  lev_routine express_output: :students

  protected

  def exec(course:)
    students = CourseMembership::Models::Student
      .joins { period }
      .where { period.entity_course_id == course.id }
      .includes(role: { role_user: { user: { profile: :account } } })

    outputs[:students] = students.collect do |student|
      Hashie::Mash.new({
        id: student.id,
        first_name: student.first_name,
        last_name: student.last_name,
        full_name: student.full_name,
        course_membership_period_id: student.course_membership_period_id,
        entity_role_id: student.entity_role_id
      })
    end
  end
end
