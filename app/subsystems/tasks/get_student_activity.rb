module Tasks
  class GetStudentActivity
    lev_routine express_output: :activity

    protected
    def exec(course:)
      course.periods.collect do |period|
        task_steps = get_task_steps(period)
        # to be continued...
      end

      outputs.activity = {
        headers: ['title', 'type', 'status', 'exercise count', 'recovered exercise count',
                  'due at', 'last worked', 'first name', 'last name']
      }
    end

    private
    def get_task_steps(period)
      task_types = Models::Task.task_types.values_at(:reading, :homework, :external)
      taskings = period.taskings.eager_load(task: {task: :task_steps})
                                .where(task: {task: {task_type: task_types}})
      taskings.flat_map { |tg| tg.task.task.task_steps }
    end
  end
end
