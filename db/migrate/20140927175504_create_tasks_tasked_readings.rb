class CreateTasksTaskedReadings < ActiveRecord::Migration
  def change
    create_table :tasks_tasked_readings do |t|
      t.string :url, null: false
      t.text :content, null: false
      t.string :title
      t.text :chapter_section

      t.timestamps null: false
    end
  end
end
