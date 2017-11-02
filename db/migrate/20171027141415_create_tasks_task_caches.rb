class CreateTasksTaskCaches < ActiveRecord::Migration
  def change
    create_table :tasks_task_caches do |t|
      t.references :tasks_task,        null: false,
                                       foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :content_ecosystem, null: false, index: true,
                                       foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.integer    :task_type,         null: false, index: true
      t.datetime   :opens_at,          index: true
      t.datetime   :due_at,            index: true
      t.datetime   :feedback_at,       index: true
      t.integer    :student_ids,       null: false, array: true, index: { using: :gin }
      t.text       :as_toc,            null: false, default: '{}'

      t.timestamps                     null: false
    end

    add_index :tasks_task_caches, [ :tasks_task_id, :content_ecosystem_id ],
              name: 'index_task_caches_on_task_id_and_ecosystem_id', unique: true
  end
end
