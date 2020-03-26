class AddExtendedTaskIdsDueAtClosesAtToTaskPlans < ActiveRecord::Migration[5.2]
  def up
    add_column :tasks_task_plans, :time_zone_id, :integer
    add_column :tasks_task_plans, :extended_task_ids, :string, array: true
    add_column :tasks_task_plans, :extended_due_at_ntz, :datetime
    add_column :tasks_task_plans, :extended_closes_at_ntz, :datetime

    Tasks::Models::TaskPlan.preload(
      :tasks, tasking_plans: :time_zone
    ).find_in_batches do |task_plans|
      task_plans.each do |task_plan|
        tasks = task_plan.tasks.reject { |task| task.accepted_late_at.nil? }

        time_zone = task_plan.tasking_plans.first&.time_zone || task_plan.owner&.time_zone
        task_plan.time_zone = time_zone
        task_plan.extended_task_ids = tasks.map(&:id)
        last_accepted_late_at_ntz = tasks.map(&:accepted_late_at).max.in_time_zone(
          time_zone.name
        )
        task_plan.extended_due_at_ntz = (
          [ last_accepted_late_at_ntz ] + tasking_plans.map(&:due_at_ntz)
        ).compact.max
        task_plan.extended_closes_at_ntz = (
          [ last_accepted_late_at_ntz ] + tasking_plans.map(&:closes_at_ntz)
        ).compact.max
      end

      Tasks::Models::TaskPlan.import task_plans, validate: false, on_duplicate_key_update: {
        conflict_target: [ :id ], columns: [
          :time_zone_id, :extended_task_ids, :extended_due_at_ntz, :extended_closes_at_ntz
        ]
      }
    end

    change_column_null :tasks_task_plans, :time_zone_id, false

    change_column_default :tasks_task_plans, :extended_task_ids, []
    change_column_null :tasks_task_plans, :extended_task_ids, false

    Tasks::Models::Task.update_all(
      <<~UPDATE_SQL
        "completed_steps_count" = GREATEST(
          "completed_steps_count", "completed_accepted_late_steps_count"
        ), "completed_exercise_steps_count" = GREATEST(
          "completed_exercise_steps_count", "completed_accepted_late_exercise_steps_count"
        ), "correct_exercise_steps_count" = GREATEST(
          "correct_exercise_steps_count", "correct_accepted_late_exercise_steps_count"
        )
      UPDATE_SQL
    )

    remove_column :tasks_tasks, :accepted_late_at
    remove_column :tasks_tasks, :completed_on_time_steps_count
    remove_column :tasks_tasks, :completed_on_time_exercise_steps_count
    remove_column :tasks_tasks, :correct_on_time_exercise_steps_count
    remove_column :tasks_tasks, :completed_accepted_late_steps_count
    remove_column :tasks_tasks, :completed_accepted_late_exercise_steps_count
    remove_column :tasks_tasks, :correct_accepted_late_exercise_steps_count
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
