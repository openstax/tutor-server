class MoveCanBeRecoveredFromTaskedExercisesToTaskSteps < ActiveRecord::Migration
  def change
    add_column :tasks_task_steps, :can_be_recovered, :boolean, null: false, default: false

    reversible do |dir|
      dir.up do
        Tasks::Models::TaskStep.update_all(
          'can_be_recovered = tasks_tasked_exercises.can_be_recovered ' +
          'FROM tasks_tasked_exercises ' +
          'WHERE tasked_id = tasks_tasked_exercises.id ' +
          'AND tasked_type = \'Tasks::Models::TaskedExercise\''
        )
      end

      dir.down do
        Tasks::Models::TaskedExercise.update_all(
          'can_be_recovered = tasks_task_steps.can_be_recovered ' +
          'FROM tasks_task_steps ' +
          'WHERE tasks_task_steps.tasked_id = tasks_tasked_exercises.id ' +
          'AND tasks_task_steps.tasked_type = \'Tasks::Models::TaskedExercise\''
        )
      end
    end

    remove_column :tasks_tasked_exercises, :can_be_recovered, :boolean, null: false, default: false
  end
end
