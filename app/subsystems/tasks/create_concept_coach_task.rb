module Tasks
  class CreateConceptCoachTask
    lev_routine express_output: :task

    uses_routine BuildTask,
      translations: { outputs: { type: :verbatim } },
      as: :build_task

    protected

    def exec(page:, exercises:, related_content_array: [])
      # In a multi-web server environment, it is possible for one server to create
      # the practice task and another to request it very quickly and if the server
      # times are not completely sync'd the request can be reject because the task
      # looks non open.  When we have ConceptCoachTasks maybe they can not have an opens_at
      # but for now HACK it by setting it to open in the near past.
      task_time = 10.minutes.ago

      run(:build_task, task_type: :concept_coach,
                       title: 'Concept Coach',
                       opens_at: task_time,
                       feedback_at: task_time)

      exercises.each_with_index do |exercise, ii|
        step = Tasks::Models::TaskStep.new(task: outputs.task)

        step.tasked = TaskExercise[exercise: exercise, task_step: step]

        related_content = related_content_array[ii]
        step.add_related_content(related_content) unless related_content.nil?

        outputs.task.task_steps << step
      end

      outputs.task.save!

      outputs.concept_coach_task = Tasks::Models::ConceptCoachTask.create!(
        task: outputs.task.entity_task, content_page_id: page.id
      )
    end

  end
end
