module Tasks
  class CreatePracticeWidgetTask
    lev_routine express_output: :task

    uses_routine BuildTask,
      translations: { outputs: { type: :verbatim } },
      as: :build_task

    protected

    def exec(exercises:, ecosystem:, task_type: :mixed_practice, related_content_array: [])
      # In a multi-web server environment, it is possible for one server to create
      # the practice task and another to request it very quickly and if the server
      # times are not completely sync'd the request can be reject because the task
      # looks non open.  When we have PracticeTasks maybe they can not have an opens_at
      # but for now HACK it by setting it to open in the near past.
      task_time = 10.minutes.ago

      run(:build_task, task_type: task_type,
                       title: 'Practice',
                       opens_at: task_time,
                       content_ecosystem_id: ecosystem.id,
                       feedback_at: task_time)

      exercises.each_with_index do |exercise, ii|
        step = Tasks::Models::TaskStep.new(task: outputs.task)

        step.tasked = TaskExercise[exercise: exercise, task_step: step]

        related_content = related_content_array[ii]
        step.add_related_content(related_content) unless related_content.nil?

        outputs.task.task_steps << step
      end

      outputs.task.save!
    end

  end
end
