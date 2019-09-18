class SetCoreAndPersonalizedPlaceholderExerciseStepsCounts < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    Tasks::Models::Task.reset_column_information

    loop do
      tasks = []
      Tasks::Models::Task.transaction do
        tasks = Tasks::Models::Task.where(
          core_and_personalized_placeholder_exercise_steps_count: nil
        ).order(created_at: :desc).limit(100).preload(task_steps: :tasked).to_a

        break if tasks.empty?

        tasks.each do |task|
          task_steps = task.task_steps.to_a

          task.core_and_personalized_placeholder_exercise_steps_count = task_steps.count do |ts|
            ts.placeholder? &&
            (ts.fixed_group? || ts.personalized_group?) &&
            ts.tasked.exercise_type?
          end
        end

        Tasks::Models::Task.import tasks, validate: false, on_duplicate_key_update: {
          conflict_target: [:id], columns: [:core_and_personalized_placeholder_exercise_steps_count]
        }
      end

      break if tasks.empty?
    end

    change_column_null :tasks_tasks, :core_and_personalized_placeholder_exercise_steps_count, false
  end

  def down
  end
end
