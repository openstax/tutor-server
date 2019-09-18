class SetTasksTaskStepsIsCore < ActiveRecord::Migration[5.2]
  BATCH_SIZE = 1000

  # Autocommit mode because all of our transactions would be 1 statement each
  disable_ddl_transaction!

  def up
    Tasks::Models::TaskStep.reset_column_information

    # Update in batches to prevent locking the task_steps for too long
    while Tasks::Models::TaskStep.where(
      group_type: [ :fixed_group, :personalized_group ], is_core: false
    ).limit(BATCH_SIZE).update_all(is_core: true) >= BATCH_SIZE do
    end

    # TaskedExternalUrls never had their group_type set properly
    while Tasks::Models::TaskStep.where(
      tasked_type: Tasks::Models::TaskedExternalUrl.name
    ).limit(BATCH_SIZE).update_all(group_type: :fixed_group, is_core: true) >= BATCH_SIZE do
    end

    while Tasks::Models::TaskStep.where(
      is_core: nil
    ).limit(BATCH_SIZE).update_all(is_core: false) >= BATCH_SIZE do
    end

    change_column_null :tasks_task_steps, :is_core, false
  end

  def down
  end
end
