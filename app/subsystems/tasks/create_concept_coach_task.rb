module Tasks
  class CreateConceptCoachTask

    lev_routine outputs: { task: BuildTask,
                           concept_coach_task: :_self },
                uses: { name: Tasks::CreateTasking, as: :create_tasking }

    protected

    def exec(role:, page:, exercises:, related_content_array: [])
      # In a multi-web server environment, it is possible for one server to create
      # the cc task and another to request it very quickly and if the server
      # times are not completely sync'd the request can be reject because the task
      # looks non open.  When we have ConceptCoachTasks maybe they can not have an opens_at
      # but for now HACK it by setting it to open in the near past.
      task_time = 10.minutes.ago

      run(:build_task, task_type: :concept_coach,
                       title: 'Concept Coach',
                       opens_at: task_time,
                       feedback_at: task_time)

      exercises.each_with_index do |exercise, ii|
        group_type = ii < Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT ? \
                       :core_group : :spaced_practice_group
        step = Tasks::Models::TaskStep.new(task: result.task, group_type: group_type)

        step.tasked = TaskExercise.call(exercise: exercise, task_step: step)

        related_content = related_content_array[ii]
        step.add_related_content(related_content) unless related_content.nil?

        result.task.task_steps << step
      end

      result.task.save!

      run(:create_tasking, role: role, task: result.task.entity_task, period: role.student.period)

      set(concept_coach_task: Tasks::Models::ConceptCoachTask.create!(
        content_page_id: page.id, entity_role_id: role.id, task: result.task.entity_task
      ))
    end

  end
end
