require_relative 'models/entity_extensions'

class CourseMembership::GetCoursePeriods
  lev_routine

  protected

  def exec(course:)
    outputs[:periods] = Entity::Relation.new(course.periods)
  end

end
