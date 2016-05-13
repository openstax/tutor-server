module Tasks
  class CreateConceptCoachTask

    lev_routine express_output: :task

    uses_routine BuildTask,
      translations: { outputs: { type: :verbatim } },
      as: :build_task

    uses_routine Tasks::CreateTasking,
      translations: { outputs: { type: :verbatim } },
      as: :create_tasking

    protected

    def exec(role:, page:, exercises:, group_types:, related_content_array: [])
      # In a multi-web server environment, it is possible for one server to create
      # the cc task and another to request it very quickly and if the server
      # times are not completely sync'd the request can be rejected because the task
      # looks non open.  When we have ConceptCoachTasks maybe they can not have an opens_at
      # but for now HACK it by setting it to open in the near past.
      task_time = 10.minutes.ago

      run(:build_task, task_type: :concept_coach,
                       title: 'Concept Coach',
                       opens_at: task_time,
                       feedback_at: task_time)

      exercises.each_with_index do |exercise, ii|
        TaskExercise.call(exercise: exercise, task: outputs.task) do |step|
          step.group_type = group_types[ii]
          step.add_related_content(related_content_array[ii])
        end
      end

      outputs.task.save!

      run(:create_tasking, role: role, task: outputs.task.entity_task, period: role.student.period)

      outputs.concept_coach_task = Tasks::Models::ConceptCoachTask.create!(
        content_page_id: page.id, entity_role_id: role.id, task: outputs.task.entity_task
      )
    end

  end
end
