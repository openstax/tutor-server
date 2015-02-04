class CreateTaskStepExercises < ActiveRecord::Migration
  def change
    create_table :task_step_exercises do |t|
      t.timestamps null: false
    end
  end
end
