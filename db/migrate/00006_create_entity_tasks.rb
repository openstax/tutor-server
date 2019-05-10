class CreateEntityTasks < ActiveRecord::Migration[4.2]
  def change
    create_table :entity_tasks do |t|
      t.timestamps null: false
    end
  end
end
