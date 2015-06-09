class CourseMembership::GetCoursePeriods
  lev_routine express_output: :periods

  protected

  def exec(course:)
    outputs[:periods] = Entity::Relation.new(course.periods)
  end

end
