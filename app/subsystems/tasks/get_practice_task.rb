class Tasks::GetPracticeTask
  lev_routine express_output: :task

  protected

  def exec(role:)
    task_types = [Tasks::Models::Task.task_types[:chapter_practice],
                  Tasks::Models::Task.task_types[:page_practice],
                  Tasks::Models::Task.task_types[:mixed_practice]]
    outputs[:task] = Tasks::Models::Task.joins{taskings}
                                        .where{taskings.entity_role_id == role.id}
                                        .where{task_type.in my { task_types }}
                                        .order{created_at}
                                        .last
  end
end
