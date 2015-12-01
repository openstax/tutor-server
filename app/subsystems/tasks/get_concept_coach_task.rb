class Tasks::GetConceptCoachTask
  lev_routine express_output: :entity_task

  protected

  def exec(role:, page:)
    outputs[:entity_task] = Tasks::Models::ConceptCoachTask
      .joins(:page)
      .where(page: { uuid: page.uuid }, entity_role_id: role.id)
      .lock.take.try(:task)
  end
end
