module Tasks
  class GetStudentActivity
    HEADERS = ['title', 'type', 'status', 'exercise_count', 'recovered_exercise_count',
               'due_at', 'last_worked', 'first_name', 'last_name']

    lev_routine express_output: :activity

    protected
    def exec(course:)
      outputs.activity = { headers: humanized_headers, data: [] }
      task_steps(course).each { |ts| outputs.activity[:data] << task_step_values(ts) }
    end

    private
    def humanized_headers
      HEADERS.map { |h| h.gsub('_', ' ') }
    end

    def task_steps(course)
      course.periods.flat_map { |p| get_functional_tasks(p) }
    end

    def get_functional_tasks(period)
      task_types = Models::Task.task_types.values_at(:reading, :homework, :external)
      taskings = period.taskings.eager_load(task: {task: :task_steps})
                                .where(task: {task: {task_type: task_types}})
      taskings.flat_map { |tasking| functionalized_task(tasking) }
    end

    def functionalized_task(tasking)
      task = tasking.task.task
      OpenStruct.new(title: task.task_plan.title,
                     type: task.task_type,
                     status: task.status,
                     exercise_count: task.actual_and_placeholder_exercise_count,
                     recovered_exercise_count: task.recovered_exercise_steps_count,
                     due_at: task.due_at.to_s,
                     worked_at: task.last_worked_at.to_s,
                     first_name: tasking.role.user.profile.account.first_name,
                     last_name: tasking.role.user.profile.account.last_name)
    end

    def task_step_values(task_step)
      HEADERS.flat_map { |h| task_step.send(h) }
    end
  end
end
