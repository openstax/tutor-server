class SupportWilloLabs < ActiveRecord::Migration
  def change
    add_column :lms_nonces, :app_type, :int, default: 0, null: false
    change_column_null :lms_contexts, :course_profile_course_id, true
  end
end
