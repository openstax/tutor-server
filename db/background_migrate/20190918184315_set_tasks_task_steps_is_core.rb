class SetTasksTaskStepsIsCore < ActiveRecord::Migration[5.2]
  BATCH_SIZE = 1000

  # Autocommit mode because all of our transactions would be 1 statement each
  disable_ddl_transaction!

  def up
    Tasks::Models::TaskStep.reset_column_information

    # Fixed group steps are always core
    while Tasks::Models::TaskStep.where(
      group_type: :fixed_group, is_core: false
    ).limit(BATCH_SIZE).update_all(is_core: true) >= BATCH_SIZE do
    end

    # Personalized group steps in readings are core if they are not among the last 3 steps
    while Tasks::Models::TaskStep.joins(:task).where(
      group_type: [ :personalized_group ], is_core: false, task: { task_type: :reading }
    ).where(
      <<~WHERE_SQL
        (
          SELECT COUNT(*)
          FROM "tasks_task_steps" "ts"
          WHERE "ts"."tasks_task_id" = "tasks_tasks"."id"
            AND "ts"."number" > "tasks_task_steps"."number"
        ) >= 3
      WHERE_SQL
    ).limit(BATCH_SIZE).update_all(is_core: true) >= BATCH_SIZE do
    end

    # TaskedExternalUrls never had their group_type set properly
    while Tasks::Models::TaskStep.where(
      tasked_type: Tasks::Models::TaskedExternalUrl.name
    ).limit(BATCH_SIZE).update_all(group_type: :fixed_group, is_core: true) >= BATCH_SIZE do
    end

    # Everything else is not core
    while Tasks::Models::TaskStep.where(
      is_core: nil
    ).limit(BATCH_SIZE).update_all(is_core: false) >= BATCH_SIZE do
    end

    change_column_null :tasks_task_steps, :is_core, false
  end

  def down
  end
end
