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
      run(:build_task, task_type: :concept_coach, title: 'Concept Coach')

      exercises.each_with_index do |exercise, ii|
        TaskExercise.call(exercise: exercise, task: outputs.task) do |step|
          step.group_type = group_types[ii]
          step.add_related_content(related_content_array[ii])
        end
      end

      period = role.student.period

      outputs.task.time_zone = period.course.time_zone

      outputs.task.save!

      entity_task = outputs.task.entity_task

      run(:create_tasking, role: role, task: entity_task, period: period)

      outputs.concept_coach_task = Tasks::Models::ConceptCoachTask.create!(
        content_page_id: page.id, entity_role_id: role.id, task: entity_task
      )
    end

  end
end
