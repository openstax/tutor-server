class CreateTaskStepInteractives < ActiveRecord::Migration
  def change
    create_table :task_step_interactives do |t|
      t.timestamps null: false
    end
  end
end
