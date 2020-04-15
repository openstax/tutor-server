class CreateTasksGradings < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks_gradings do |t|
      t.references :tasks_tasked_exercise, foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.float :points, null: false
      t.text :comments, null: false

      t.timestamps
    end
  end
end
