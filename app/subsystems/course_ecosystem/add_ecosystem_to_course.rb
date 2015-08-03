class CourseEcosystem::AddEcosystemToCourse
  lev_routine

  protected

  def exec(course:, ecosystem:, remove_other_ecosystems: false)
    course.reload.ecosystems.destroy_all if remove_other_ecosystems
    course_ecosystem = CourseEcosystem::Models::CourseEcosystem.create(course: course,
                                                                     ecosystem: ecosystem)
    transfer_errors_from(course_ecosystem, {type: :verbatim}, true)
  end
end
