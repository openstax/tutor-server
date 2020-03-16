class AddCorePageIdsToTasksTasks < ActiveRecord::Migration[5.2]
  def up
    add_column :tasks_tasks, :core_page_ids, :integer, array: true

    # https://dba.stackexchange.com/a/211502
    Tasks::Models::Task.update_all(
      <<~UPDATE_SQL
        "core_page_ids" = ARRAY(
          SELECT "unsorted"."content_page_id"
          FROM (
            SELECT DISTINCT ON ("tasks_task_steps"."content_page_id")
              "tasks_task_steps"."content_page_id", "tasks_task_steps"."number"
            FROM "tasks_task_steps"
            WHERE "tasks_task_steps"."tasks_task_id" = "tasks_tasks"."id"
              AND "tasks_task_steps"."is_core" = true
            ORDER BY "tasks_task_steps"."content_page_id", "tasks_task_steps"."number"
          ) "unsorted"
          ORDER BY "unsorted"."number"
        )
      UPDATE_SQL
    )

    change_column_default :tasks_tasks, :core_page_ids, []
    change_column_null :tasks_tasks, :core_page_ids, false
  end

  def down
    remove_column :tasks_tasks, :core_page_ids
  end
end
