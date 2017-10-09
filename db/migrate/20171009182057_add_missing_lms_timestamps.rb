class AddMissingLmsTimestamps < ActiveRecord::Migration
  def change
    change_column_null :lms_apps, :created_at, false
    change_column_null :lms_apps, :updated_at, false

    add_column :lms_contexts, :created_at, :datetime, null: false, default: '2017-09-14 00:00:00'
    add_column :lms_contexts, :updated_at, :datetime, null: false, default: '2017-09-14 00:00:00'
    change_column_default :lms_contexts, :created_at, nil
    change_column_default :lms_contexts, :updated_at, nil

    add_column :lms_course_score_callbacks, :created_at, :datetime,
               null: false, default: '2017-09-14 00:00:00'
    add_column :lms_course_score_callbacks, :updated_at, :datetime,
               null: false, default: '2017-09-14 00:00:00'
    change_column_default :lms_course_score_callbacks, :created_at, nil
    change_column_default :lms_course_score_callbacks, :updated_at, nil

    add_column :lms_nonces, :updated_at, :datetime, null: false, default: '2017-09-14 00:00:00'
    change_column_null :lms_nonces, :created_at, false
    change_column_default :lms_nonces, :updated_at, nil

    add_column :lms_tool_consumers, :created_at, :datetime,
               null: false, default: '2017-09-14 00:00:00'
    add_column :lms_tool_consumers, :updated_at, :datetime,
               null: false, default: '2017-09-14 00:00:00'
    change_column_default :lms_tool_consumers, :created_at, nil
    change_column_default :lms_tool_consumers, :updated_at, nil

    add_column :lms_trusted_launch_data, :updated_at, :datetime,
               null: false, default: '2017-09-14 00:00:00'
    change_column_default :lms_trusted_launch_data, :created_at, nil
    change_column_default :lms_trusted_launch_data, :updated_at, nil

    add_column :lms_users, :created_at, :datetime, null: false, default: '2017-09-14 00:00:00'
    add_column :lms_users, :updated_at, :datetime, null: false, default: '2017-09-14 00:00:00'
    change_column_default :lms_users, :created_at, nil
    change_column_default :lms_users, :updated_at, nil
  end
end
