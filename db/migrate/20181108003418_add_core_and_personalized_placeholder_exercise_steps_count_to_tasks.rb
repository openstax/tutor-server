class AddCoreAndPersonalizedPlaceholderExerciseStepsCountToTasks < ActiveRecord::Migration
  def change
    add_column :tasks_tasks, :core_and_personalized_placeholder_exercise_steps_count, :integer,
               null: false, default: 0

    Tasks::Models::Task.reset_column_information

    Tasks::Models::Task.where('"placeholder_exercise_steps_count" > 0')
                       .preload(task_steps: :tasked)
                       .find_in_batches do |tasks|
      tasks.each do |task|
        task.core_and_personalized_placeholder_exercise_steps_count = task.task_steps.count do |ts|
          ts.placeholder? && (ts.core_group? || ts.personalized_group?) && ts.tasked.exercise_type?
        end
      end

      Tasks::Models::Task.import tasks, validate: false, on_duplicate_key_update: {
        conflict_target: [:id], columns: [:core_and_personalized_placeholder_exercise_steps_count]
      }
    end
  end
end
