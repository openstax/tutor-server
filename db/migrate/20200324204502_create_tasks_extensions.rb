class CreateTasksExtensions < ActiveRecord::Migration[5.2]
  def up
    create_table :tasks_extensions do |t|
      t.references :tasks_task_plan, null: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :entity_role, null: false, index: true,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :time_zone, null: false

      t.datetime :due_at_ntz, null: false
      t.datetime :closes_at_ntz, null: false
    end

    add_index :tasks_extensions, [ :tasks_task_plan_id, :entity_role_id ], unique: true

    add_reference :tasks_tasks, :tasks_extension,
                  foreign_key: { on_update: :cascade, on_delete: :nullify }

    Tasks::Models::Task.where.not(tasks_task_plan_id: nil)
                       .where.not(accepted_late_at: nil)
                       .where.not(time_zone_id: nil)
                       .preload(:taskings, :time_zone)
                       .find_in_batches do |tasks|
      extensions = tasks.map do |task|
        accepted_late_at_ntz = task.accepted_late_at.in_time_zone(task.time_zone.name)

        Tasks::Models::Extension.new(
          tasks_task_plan_id: task.tasks_task_plan_id,
          entity_role_id: task.taskings.first.entity_role_id,
          time_zone: task.time_zone,
          due_at_ntz: [ accepted_late_at_ntz, task.due_at_ntz ].compact.max,
          closes_at_ntz: [ accepted_late_at_ntz, task.closes_at_ntz ].compact.max
        )
      end

      Tasks::Models::Extension.import extensions, validate: false

      Tasks::Models::Task.import tasks, validate: false, on_duplicate_key_update: {
        conflict_target: [ :id ], columns: [ :tasks_extension_id ]
      }
    end

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
