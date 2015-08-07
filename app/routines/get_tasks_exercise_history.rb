class GetTasksExerciseHistory
  lev_routine express_output: :exercise_history

  protected

  def exec(ecosystem:, tasks:)
    outputs[:exercise_history] = [tasks].flatten.collect do |task|
      exercise_ids = task.task_steps
                         .select{ |task_step| task_step.exercise? }
                         .collect{ |task_step| task_step.tasked.content_exercise_id }
      ecosystem.exercises_by_ids(exercise_ids)
    end
  end
end
