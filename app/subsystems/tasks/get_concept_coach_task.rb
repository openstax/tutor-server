class Tasks::GetConceptCoachTask
  lev_routine express_output: :task

  protected

  def exec(role:, page:)
    outputs[:task] = Tasks::Models::ConceptCoachTask
      .joins(:page)
      .where(page: { uuid: page.uuid }, entity_role_id: role.id)
      .lock.take.try!(:task)
  end
end
