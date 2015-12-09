module Manager::CourseDetails
  protected

  def get_course_details
    @course = Entity::Course.find(params[:id])
    @profile = GetCourseProfile.call(course: @course)
    @periods = @course.periods
    @teachers = @course.teachers.includes(role: { profile: :account })
    @ecosystems = Content::ListEcosystems.call

    @course_ecosystem = nil
    ecosystem_model = @course.ecosystems.first
    return if ecosystem_model.nil?

    ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(ecosystem_model)
    @course_ecosystem = ::Content::Ecosystem.new(strategy: ecosystem_strategy)

    @catalog_offerings = Catalog::ListOfferings.call
  end
end
