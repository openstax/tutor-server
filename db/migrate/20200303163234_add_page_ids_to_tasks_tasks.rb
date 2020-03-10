class AddPageIdsToTasksTasks < ActiveRecord::Migration[5.2]
  def up
    add_column :tasks_tasks, :page_ids, :integer, array: true

    # https://dba.stackexchange.com/a/211502
    Tasks::Models::Task.update_all(
      <<~UPDATE_SQL
        "page_ids" = ARRAY(
          SELECT "unsorted"."content_page_id"
          FROM (
            SELECT DISTINCT ON ("tasks_task_steps"."content_page_id")
              "tasks_task_steps"."content_page_id", "tasks_task_steps"."number"
            FROM "tasks_task_steps"
            WHERE "tasks_task_steps"."tasks_task_id" = "tasks_tasks"."id"
            ORDER BY "tasks_task_steps"."content_page_id", "tasks_task_steps"."number"
          ) "unsorted"
          ORDER BY "unsorted"."number"
        )
      UPDATE_SQL
    )

    change_column_default :tasks_tasks, :page_ids, []
    change_column_null :tasks_tasks, :page_ids, false
  end

  def down
    remove_column :tasks_tasks, :page_ids
  end
end
