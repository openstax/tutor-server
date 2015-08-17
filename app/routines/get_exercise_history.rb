class GetExerciseHistory
  lev_routine express_output: :exercise_history

  protected

  def exec(ecosystem:, entity_tasks:)
    outputs[:exercise_history] = [entity_tasks].flatten.collect do |entity_task|
      content_exercise_ids = entity_task.task
                                        .task_steps
                                        .select{ |task_step| task_step.exercise? }
                                        .collect{ |task_step| task_step.tasked.content_exercise_id }

      # Get the exercise numbers for exercises in the user's history
      exercise_numbers = Content::Models::Exercise.where(id: content_exercise_ids).pluck(:number)

      # Get the equivalent exercises in the current ecosystem
      ecosystem.exercises_by_numbers(exercise_numbers)
    end
  end
end
