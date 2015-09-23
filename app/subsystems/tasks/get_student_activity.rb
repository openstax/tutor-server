module Tasks
  class GetStudentActivity
    HEADERS = %w(title type status exercise_count recovered_exercise_count due_at
                 last_worked can_be_recovered url free_response
                 answer_id book_location first_name last_name)

    lev_routine express_output: :activity

    protected
    def exec(course:)
      outputs.activity = {
        headers: humanized_headers,
        data: task_data(course)
      }
    end

    private
    def humanized_headers
      HEADERS.map { |h| h.gsub('_', ' ') }
    end

    def task_data(course)
      tasks = course.periods.flat_map { |p| get_functional_tasks(p) }
      tasks.map { |t| task_values(t) }
    end

    def get_functional_tasks(period)
      task_types = Models::Task.task_types.values_at(:reading, :homework, :external)

      taskings = period.taskings.eager_load(task: :task)
                                .where(task: {task: {task_type: task_types}})

      tasks = taskings.flat_map { |tasking| tasking.task.task }

      functional_tasks = taskings.flat_map do |tasking|
        task = tasking.task.task
        functionalized_task(task, tasking)
      end

      functional_taskeds = tasks.flat_map do |task|
        t = task.task_steps.flat_map(&:tasked)
        t.flat_map { |tasked| functionalized_task(tasked) }
      end

      functional_tasks + functional_taskeds
    end

    def functionalized_task(task, tasking = nil)
      OpenStruct.new(
        title: attempt_value(task, :title),
        type: attempt_value(task, :task_type),
        status: attempt_value(task, :status),
        exercise_count: attempt_value(task, :actual_and_placeholder_exercise_count),
        recovered_exercise_count: attempt_value(task, :recovered_exercise_count),
        due_at: attempt_value(task, :due_at).to_s,
        worked_at: attempt_value(task, :worked_at).to_s,
        can_be_recovered: attempt_value(task, :can_be_recovered),
        url: attempt_value(task, :url),
        free_response: attempt_value(task, :free_response),
        answer_id: attempt_value(task, :answer_id),
        book_location: attempt_value(task, :book_location),
        first_name: attempt_value(tasking, :role, :user, :profile, :account, :first_name),
        last_name: attempt_value(tasking, :role, :user, :profile, :account, :last_name)
      )
    end

    def attempt_value(obj, *method_names)
      val = obj

      method_names.each do |method_name|
        val = val.respond_to?(method_name) ? val.send(method_name) : nil
      end

      val
    end

    def task_values(task)
      HEADERS.flat_map { |h| task.send(h) }
    end
  end
end
