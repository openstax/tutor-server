class CreateTasksTaskPlans < ActiveRecord::Migration[4.2]
  def change
    create_table :tasks_task_plans do |t|
      t.references :tasks_assistant, null: false, index: true,
                                     foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :owner, polymorphic: true, null: false
      t.string :type, null: false
      t.string :title, null: false
      t.text :description
      t.text :settings, null: false
      t.datetime :publish_last_requested_at
      t.datetime :published_at
      t.string :publish_job_uuid
      t.timestamps null: false

      t.index [:owner_id, :owner_type]
    end
  end
end
