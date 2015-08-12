class CreateEntityTasks < ActiveRecord::Migration
  def change
    create_table :entity_tasks do |t|
      t.timestamps null: false
    end
  end
end
