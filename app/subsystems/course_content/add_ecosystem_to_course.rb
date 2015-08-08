class CourseContent::AddEcosystemToCourse
  lev_routine

  protected

  def exec(course:, ecosystem:, remove_other_ecosystems: false)
    course.reload.ecosystems.destroy_all if remove_other_ecosystems
    course_ecosystem = CourseContent::Models::CourseEcosystem.create(
      course: course, content_ecosystem_id: ecosystem.id
    )
    course.course_ecosystems << course_ecosystem
    transfer_errors_from(course_ecosystem, {type: :verbatim}, true)
  end
end
