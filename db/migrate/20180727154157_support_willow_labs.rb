class SupportWillowLabs < ActiveRecord::Migration
  def change

#    remove_index :lms_nonces, name: 'lms_nonce_app_value'
    add_column :lms_nonces, :app_type, :int, default: 0, null: false
    change_column_null :lms_context, :course_profile_course_id, true

    # change_column_null :lms_nonces, :lms_app_id, true

  end
end
