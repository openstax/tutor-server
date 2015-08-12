class GetExerciseHistory
  lev_routine express_output: :exercise_history

  protected

  def exec(ecosystem:, entity_tasks:)
    outputs[:exercise_history] = [entity_tasks].flatten.collect do |entity_task|
      exercise_ids = entity_task.task.task_steps
                                .select{ |task_step| task_step.exercise? }
                                .collect{ |task_step| task_step.tasked.content_exercise_id }
      ecosystem.exercises_by_ids(exercise_ids)
    end
  end
end
