class CreateTasksTaskedVideos < ActiveRecord::Migration[4.2]
  def change
    create_table :tasks_tasked_videos do |t|
      t.string :url, null: false
      t.text :content, null: false
      t.string :title

      t.timestamps null: false
    end
  end
end
