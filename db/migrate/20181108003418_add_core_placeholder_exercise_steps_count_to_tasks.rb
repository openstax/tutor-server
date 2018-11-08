class AddCorePlaceholderExerciseStepsCountToTasks < ActiveRecord::Migration
  def change
    add_column :tasks_tasks, :core_placeholder_exercise_steps_count, :integer,
               null: false, default: 0

    Tasks::Models::Task.reset_column_information

    Tasks::Models::Task.where('"placeholder_exercise_steps_count" > 0')
                       .preload(task_steps: :tasked)
                       .find_in_batches do |tasks|
      tasks.each do |task|
        task.core_placeholder_exercise_steps_count = task.task_steps.count do |task_step|
          task_step.placeholder? && task_step.core_group? && task_step.tasked.exercise_type?
        end
      end

      Tasks::Models::Task.import tasks, validate: false, on_duplicate_key_update: {
        conflict_target: [:id], columns: [:core_placeholder_exercise_steps_count]
      }
    end
  end
end
