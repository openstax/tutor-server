class PreviewClaimed < ActiveRecord::Migration[4.2]
  def change
    add_column :course_profile_courses, :preview_claimed_at, :timestamp
    add_index :course_profile_courses,
              [:catalog_offering_id, :is_preview, :preview_claimed_at],
              name: :preview_pending_indx
  end
end
