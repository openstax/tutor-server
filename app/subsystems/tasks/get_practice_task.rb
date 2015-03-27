require_relative 'models/entity_extensions'

class Tasks::GetPracticeTask
  lev_routine

  protected

  def exec(role:)
    outputs[:task] = Tasks::Models::LegacyTaskMap.joins{task}
                                         .joins{task.taskings}
                                         .where{task.taskings.entity_role_id == role.id}
                                         .order{created_at}
                                         .last
                                         .try(:legacy_task)
  end
end
