class Tasks::GetConceptCoachTask
  lev_routine outputs: { entity_task: :_self }

  protected

  def exec(role:, page:)
    set(entity_task: Tasks::Models::ConceptCoachTask
                       .joins(:page)
                       .where(page: { uuid: page.uuid }, entity_role_id: role.id)
                       .lock.take.try(:task))
  end
end
