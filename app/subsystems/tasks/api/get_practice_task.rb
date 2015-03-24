class Tasks::Api::GetPracticeTask
  lev_routine

  protected

  def exec(role:)
    outputs[:task] = Tasks::LegacyTaskMap.joins{task}
                                         .joins{task.taskings}
                                         .where{task.taskings.entity_role_id == 1}
                                         .order{created_at}
                                         .last
                                         .try(:legacy_task)
  end
end