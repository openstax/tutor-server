class SearchCourses
  lev_routine express_output: :courses

  protected

  def exec(query:)
    outputs[:courses] = Entity::Course.all
  end

end
