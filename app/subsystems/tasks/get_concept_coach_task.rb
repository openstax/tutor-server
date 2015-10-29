class Tasks::GetConceptCoachTask
  lev_routine express_output: :entity_task

  protected

  def exec(role:, page:)
    outputs[:entity_task] = Tasks::Models::ConceptCoachTask
      .joins(entity_task: :taskings)
      .where(content_page_id: page.id, entity_task: { taskings: { entity_role_id: role.id } })
      .take.try(:entity_task)
  end
end
