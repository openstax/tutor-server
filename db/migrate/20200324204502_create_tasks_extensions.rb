class CreateTasksExtensions < ActiveRecord::Migration[5.2]
  def up
    create_table :tasks_extensions do |t|
      t.references :tasks_task_plan, null: false, index: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :entity_role, null: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :time_zone, null: false

      t.datetime :due_at_ntz, null: false
      t.datetime :closes_at_ntz, null: false
    end

    add_index :tasks_extensions, [ :tasks_task_plan_id, :entity_role_id ], unique: true

    Tasks::Models::Task.where.not(tasks_task_plan_id: nil)
                       .where.not(accepted_late_at: nil)
                       .where.not(time_zone_id: nil)
                       .preload(:task_plan, :time_zone, taskings: :role)
                       .find_in_batches do |tasks|
      extensions = tasks.map do |task|
        accepted_late_at_ntz = task.accepted_late_at.in_time_zone(task.time_zone.name)

        Tasks::Models::Extension.new(
          task_plan: task.task_plan,
          role: task.taskings.first.role,
          time_zone: task.time_zone,
          due_at_ntz: [ accepted_late_at_ntz, task.due_at_ntz ].compact.max,
          closes_at_ntz: [ accepted_late_at_ntz, task.closes_at_ntz ].compact.max
        )
      end

      Tasks::Models::Extension.import extensions, validate: false

      tasks.each(&:update_caches_later)
    end

    remove_column :tasks_tasks, :accepted_late_at
    remove_column :tasks_tasks, :completed_accepted_late_steps_count
    remove_column :tasks_tasks, :completed_accepted_late_exercise_steps_count
    remove_column :tasks_tasks, :correct_accepted_late_exercise_steps_count
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
