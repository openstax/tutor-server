class Tasks::GetPracticeTask
  lev_routine outputs: { task: :_self }

  protected

  def exec(role:)
    task_types = [Tasks::Models::Task.task_types[:chapter_practice],
                  Tasks::Models::Task.task_types[:page_practice],
                  Tasks::Models::Task.task_types[:mixed_practice]]
    set(task: Tasks::Models::Task.joins{entity_task.taskings}
                                 .where{entity_task.taskings.entity_role_id == role.id}
                                 .where{task_type.in my { task_types }}
                                 .order{created_at}
                                 .last
                                 .try(:entity_task))
  end
end
