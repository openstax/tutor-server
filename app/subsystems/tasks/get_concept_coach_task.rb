class Tasks::GetConceptCoachTask
  lev_routine express_output: :entity_task

  protected

  def exec(role:, page:)
    outputs[:entity_task] = Tasks::Models::ConceptCoachTask
      .where(content_page_id: page.id, entity_role_id: role.id)
      .lock.take.try(:task)
  end
end
