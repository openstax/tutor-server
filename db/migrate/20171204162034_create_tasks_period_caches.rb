class CreateTasksPeriodCaches < ActiveRecord::Migration[4.2]
  def change
    create_table :tasks_period_caches do |t|
      t.references :course_membership_period, null: false, index: true,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :content_ecosystem,        null: false, index: true,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :tasks_task_plan,                       index: true,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.datetime   :opens_at,                              index: true
      t.datetime   :due_at,                                index: true
      t.integer    :student_ids,              null: false, array: true, index: { using: :gin }
      t.text       :as_toc,                   null: false, default: '{}'
      t.timestamps                            null: false
    end

    add_index :tasks_period_caches,
              [ :course_membership_period_id, :content_ecosystem_id, :tasks_task_plan_id ],
              name: 'index_period_caches_on_c_m_p_id_and_c_e_id_and_t_t_p_id', unique: true
    add_index :tasks_period_caches,
              [ :course_membership_period_id, :content_ecosystem_id ],
              where: '"tasks_task_plan_id" IS NULL',
              name: 'index_period_caches_on_c_m_p_id_and_c_e_id', unique: true
  end
end
