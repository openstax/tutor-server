class CourseEcosystem::GetCourseBooks
  lev_routine express_output: :books

  protected

  def exec(course:)
    course_ecosystems = CourseEcosystem::Models::CourseEcosystem.where(course: course.id)
    outputs[:books] = course_ecosystems.collect{ |ce| ce.ecosystem.books }.flatten
  end
end
