module Tasks
  class IsReady
    lev_routine express_output: :ready_task_ids

    protected

    def exec(tasks:, biglearn_api_method: :fetch_assignment_pes,
             inline_max_attempts: 1, inline_sleep_interval: 0, enable_warnings: false)
      ready_tasks, tasks_needing_pes = tasks.partition do |task|
        task.pes_are_assigned || task.core_placeholder_exercise_steps_count == 0
      end

      requests = tasks_needing_pes.map do |task|
        {
          task: task,
          max_num_exercises: task.core_placeholder_exercise_steps_count,
          inline_max_attempts: inline_max_attempts,
          inline_sleep_interval: inline_sleep_interval,
          enable_warnings: enable_warnings
        }
      end

      outputs.ready_task_ids = Set.new(ready_tasks.map(&:id))

      OpenStax::Biglearn::Api.public_send(biglearn_api_method, requests).each do |request, response|
        outputs.ready_task_ids << request[:task].id if response[:accepted]
      end unless requests.empty?
    end
  end
end
