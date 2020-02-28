class CourseContent::GetCourseEcosystems
  lev_routine express_output: :ecosystems

  protected

  def exec(course:)
    outputs.ecosystems = course.ecosystems
  end
end
