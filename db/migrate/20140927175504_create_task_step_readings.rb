class CreateTaskStepReadings < ActiveRecord::Migration
  def change
    create_table :task_step_readings do |t|
      t.timestamps null: false
    end
  end
end
