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
      course = role.student.course

      fatal_error(code: :course_not_started) unless course.started?
      fatal_error(code: :course_ended) if course.ended?

      period = role.student.period
      time_zone = course.time_zone

      run(
        :build_task,
        task_type: :concept_coach,
        title: 'Concept Coach',
        time_zone: time_zone,
        ecosystem: page.to_model.ecosystem
      )

      exercises.each_with_index do |exercise, ii|
        TaskExercise.call(exercise: exercise, task: outputs.task) do |step|
          step.group_type = group_types[ii]
          step.add_related_content(related_content_array[ii])
        end
      end

      outputs.task.save!

      run(:create_tasking, role: role, task: outputs.task, period: period)

      outputs.concept_coach_task = Tasks::Models::ConceptCoachTask.create!(
        content_page_id: page.id, entity_role_id: role.id, task: outputs.task
      )
    end

  end
end
