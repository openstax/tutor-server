class SupportWilloLabs < ActiveRecord::Migration[4.2]
  def change
    # change app_id to be nullable and non-unique so it can
    # be re-used by willo labs
    remove_index :lms_nonces, name: 'lms_nonce_app_value'
    add_index :lms_nonces, :lms_app_id
    change_column_null :lms_nonces, :lms_app_id, true
    add_column :lms_nonces, :app_type, :int, default: 0, null: false

    # allow creating a context where the course is provided after the
    # instructor finds-or-creates one
    change_column_null :lms_contexts, :course_profile_course_id, true
  end
end
