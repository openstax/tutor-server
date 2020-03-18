class GetCourseEcosystemsMap
  lev_routine express_output: :ecosystems_map

  protected

  def exec(course:)
    to_ecosystem = course.ecosystem

    raise 'The given course has no ecosystems' if to_ecosystem.nil?

    course_ecosystems = course.ecosystems.to_a
    tp_ecosystem_ids = Tasks::Models::TaskPlan.distinct
                                              .where(owner: course)
                                              .pluck(:content_ecosystem_id)
    tp_ecosystems = Content::Models::Ecosystem.where(id: tp_ecosystem_ids).to_a

    from_ecosystems = (course_ecosystems + tp_ecosystems).uniq

    outputs.ecosystems_map = Content::Map.find_or_create_by(
      from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem
    )
  end
end
