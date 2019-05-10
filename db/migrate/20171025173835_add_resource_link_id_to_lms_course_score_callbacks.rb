class AddResourceLinkIdToLmsCourseScoreCallbacks < ActiveRecord::Migration[4.2]
  def up
    # Callbacks should have had a resource_link_id on them, and in the new
    # way of things it doesn't make sense to have any without them, so blow
    # away existing (ok since not yet used on prod, and on other systems
    # will just require students relaunching).
    Lms::Models::CourseScoreCallback.destroy_all

    add_column :lms_course_score_callbacks, :resource_link_id, :string, null: false

    remove_index :lms_course_score_callbacks, name: "course_score_callbacks_on_course_user_result_outcome"
    add_index :lms_course_score_callbacks, [:course_profile_course_id, :user_profile_id, :resource_link_id],
                                           name: "course_score_callbacks_on_course_user_link",
                                           unique: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
