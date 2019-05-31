class AddLmsIndexUniqueness < ActiveRecord::Migration[4.2]
  def change
    remove_index :lms_apps, name: "index_lms_apps_on_key"
    add_index :lms_apps, :key, unique: true

    remove_index :lms_apps, name: "index_lms_apps_on_owner_type_and_owner_id"
    add_index :lms_apps, [:owner_type, :owner_id], unique: true

    remove_index :lms_course_score_callbacks, name: "course_score_callbacks_on_course_user_result_outcome"
    add_index :lms_course_score_callbacks, [:course_profile_course_id, :user_profile_id, :result_sourcedid, :outcome_url],
                                           name: "course_score_callbacks_on_course_user_result_outcome",
                                           unique: true

    remove_index :lms_tool_consumers, name: "index_lms_tool_consumers_on_guid"
    add_index :lms_tool_consumers, :guid, name: "index_lms_tool_consumers_on_guid", unique: true
  end
end
