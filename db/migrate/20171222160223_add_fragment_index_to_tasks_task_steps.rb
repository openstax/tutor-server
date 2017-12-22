class AddFragmentIndexToTasksTaskSteps < ActiveRecord::Migration
  def change
    add_column :tasks_task_steps, :fragment_index, :integer

    reversible do |dir|
      dir.up do
        reading_type = Tasks::Models::Task.task_types[:reading]

        Tasks::Models::TaskStep.joins(:task).where(task: { task_type: reading_type }).update_all(
          <<-UPDATE_SQL.strip_heredoc
            "fragment_index" = (
              SELECT COALESCE("page_prev_steps"."fragment_index", -1) + 1
              FROM "tasks_task_steps"
              LEFT OUTER JOIN "tasks_task_steps" "page_prev_steps"
                ON "page_prev_steps"."tasks_task_id" = "tasks_task_steps"."tasks_task_id"
                  AND "page_prev_steps"."number" < "tasks_task_steps"."number"
                  AND "page_prev_steps"."content_page_id" = "tasks_task_steps"."content_page_id"
              ORDER BY "page_prev_steps"."number" DESC
              LIMIT 1
            )
          UPDATE_SQL
        )
      end
    end
  end
end
