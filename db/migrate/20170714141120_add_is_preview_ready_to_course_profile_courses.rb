class AddIsPreviewReadyToCourseProfileCourses < ActiveRecord::Migration
  def change
    remove_index :course_profile_courses,
                 column: [:catalog_offering_id, :is_preview, :preview_claimed_at],
                 name: 'preview_pending_indx'

    add_column :course_profile_courses, :is_preview_ready, :boolean, null: false, default: false

    # Preview courses that failed to build so far have been marked with preview_claimed_at
    # It should be safe to mark them as ready so they don't interfere with the counting
    reversible do |dir|
      dir.up do
        CourseProfile::Models::Course.where(is_preview: true).update_all(is_preview_ready: true)
      end
    end

    add_index :course_profile_courses,
              [:is_preview, :is_preview_ready, :preview_claimed_at, :catalog_offering_id],
              name: 'preview_pending_index'
  end
end
