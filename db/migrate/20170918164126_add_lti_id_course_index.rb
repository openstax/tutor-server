class AddLtiIdCourseIndex < ActiveRecord::Migration
  def change
    add_index :lms_contexts, [:lti_id, :lms_tool_consumer_id, :course_profile_course_id],
              unique: true, name: :lms_contexts_lti_id_tool_consumer_id_course_id
  end
end
