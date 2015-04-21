module Tasks
  class GetRoleTaskSteps
    lev_routine express_output: :task_steps

    uses_routine GetTasks,
      translations: { outputs: { type: :verbatim } },
      as: :get_tasks

    protected
    def exec(roles:)
      run(:get_tasks, roles: roles)

      outputs[:task_steps] = Models::Task.includes(task_steps: :tasked)
                                         .where(entity_task: outputs.tasks)
                                         .collect(&:task_steps)
                                         .flatten
                                         .keep_if(&:completed?)
    end
  end
end
