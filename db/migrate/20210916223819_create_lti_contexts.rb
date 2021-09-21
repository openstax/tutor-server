class CreateLtiContexts < ActiveRecord::Migration[5.2]
  def change
    create_table :lti_contexts do |t|
      t.references :course_profile_course, null: false, foreign_key: {
        on_update: :cascade, on_delete: :cascade
      }
      t.references :lti_platform, null: false, index: false, foreign_key: {
        on_update: :cascade, on_delete: :cascade
      }
      t.string :context_id, null: false

      t.timestamps

      t.index [ :lti_platform_id, :context_id ], unique: true
    end
  end
end
