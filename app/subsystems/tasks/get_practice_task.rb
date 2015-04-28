require_relative 'models/entity_extensions'

class Tasks::GetPracticeTask
  lev_routine express_output: :task

  protected

  def exec(role:)
    outputs[:task] = Tasks::Models::Task.joins{entity_task.taskings}
                                        .where{entity_task.taskings.entity_role_id == role.id}
                                        .where{task_type =~ '%-practice'}
                                        .order{created_at}
                                        .last
                                        .try(:entity_task)
  end
end
