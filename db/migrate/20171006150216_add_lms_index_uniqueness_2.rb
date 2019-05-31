class AddLmsIndexUniqueness2 < ActiveRecord::Migration[4.2]
  def change
    remove_index :lms_contexts, name: "index_lms_contexts_on_course_profile_course_id"
    add_index :lms_contexts, :course_profile_course_id, name: "index_lms_contexts_on_course_profile_course_id", unique: true
  end
end
