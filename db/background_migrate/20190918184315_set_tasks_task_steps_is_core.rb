class SetTasksTaskStepsIsCore < ActiveRecord::Migration[5.2]
  # Autocommit mode because all of our transactions would be 1 statement each
  disable_ddl_transaction!

  def up
    Tasks::Models::TaskStep.reset_column_information

    # Fixed group steps are always core
    Tasks::Models::TaskStep.where(group_type: :fixed_group).in_batches.update_all(is_core: true)

    # TaskedExternalUrls never had their group_type set properly
    Tasks::Models::TaskStep.where(
      tasked_type: Tasks::Models::TaskedExternalUrl.name
    ).in_batches.update_all(group_type: :fixed_group, is_core: true)

    # Personalized group steps in readings are core if they are not among the last 3 steps
    Tasks::Models::TaskStep.joins(:task).where(
      group_type: :personalized_group, task: { task_type: :reading }
    ).where(
      <<~WHERE_SQL
        (
          SELECT COUNT(*)
          FROM "tasks_task_steps" "ts"
          WHERE "ts"."tasks_task_id" = "tasks_tasks"."id"
            AND "ts"."number" > "tasks_task_steps"."number"
        ) >= 3
      WHERE_SQL
    ).in_batches.update_all(is_core: true)

    # Everything else is not core
    Tasks::Models::TaskStep.where(is_core: nil).in_batches.update_all(is_core: false)

    change_column_null :tasks_task_steps, :is_core, false
  end

  def down
  end
end
