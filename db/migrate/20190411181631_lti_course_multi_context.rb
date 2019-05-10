class LtiCourseMultiContext < ActiveRecord::Migration[4.2]
  def change
    # undo the uniqueness added in 20171006150216_add_lms_index_uniqueness_2.rb
    remove_index :lms_contexts, name: "index_lms_contexts_on_course_profile_course_id"
    add_index :lms_contexts, :course_profile_course_id,
              name: "index_lms_contexts_on_course_profile_course_id", unique: false
  end
end
