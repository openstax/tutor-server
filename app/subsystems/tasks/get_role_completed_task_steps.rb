module Tasks
  class GetRoleCompletedTaskSteps
    lev_routine express_output: :task_steps

    uses_routine GetTasks,
      translations: { outputs: { type: :verbatim } },
      as: :get_tasks

    protected
    def exec(roles:)
      run(:get_tasks, roles: roles)

      outputs[:task_steps] = outputs[:tasks].preload(task: {task_steps: [:task, :tasked]})
                                            .collect{ |tt| tt.task.task_steps }.flatten
                                            .select(&:completed?)
    end
  end
end
