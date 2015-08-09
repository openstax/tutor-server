class GetCourseEcosystem
  lev_routine express_output: :ecosystem

  protected

  def exec(course:)
    outputs[:ecosystem] = course.ecosystems.first
  end
end
