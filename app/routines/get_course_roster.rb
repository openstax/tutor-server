class GetCourseRoster
  lev_routine express_output: :roster

  protected

  def exec(course:)
    outputs.roster = {
      teach_url: UrlGenerator.teach_course_url(course.teach_token),
      teachers: course.teachers.without_deleted.preload(role: { profile: :account }),
      students: course.students.preload(:enrollments, role: { profile: :account })
    }
  end
end
