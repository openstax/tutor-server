class IndexTaskStepsOnPageId < ActiveRecord::Migration[5.2]
  def change
    add_index :tasks_task_steps, :content_page_id
  end
end
