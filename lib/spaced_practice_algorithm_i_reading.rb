class SpacedPracticeAlgorithmIReading
  def call(event:, task:)
    return unless task.core_task_steps_completed?

    task_steps = task.spaced_practice_task_steps.select do |ts|
      ts.tasked_type.demodulize == 'TaskedPlaceholder'
    end

    task_steps.each do |task_step|
      exercise_hash = OpenStax::Exercises::V1.fake_client.new_exercise_hash
      exercise = OpenStax::Exercises::V1::Exercise.new(exercise_hash.to_json)

      task_step.tasked.destroy!
      task_step.tasked = Tasks::Models::TaskedExercise.new(
        task_step: task_step,
        title:     exercise.title,
        url:       exercise.url,
        content:   exercise.content
      )
      task_step.tasked.save!
      task_step.save!
    end
  end
end
