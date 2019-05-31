class CreateTasksTaskedExternalUrls < ActiveRecord::Migration[4.2]
  def change
    create_table :tasks_tasked_external_urls do |t|
      t.string :url, null: false
      t.string :title

      t.timestamps null: false
    end
  end
end
