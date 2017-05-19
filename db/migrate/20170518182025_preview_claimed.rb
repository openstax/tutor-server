class PreviewClaimed < ActiveRecord::Migration
  def change
    add_column :course_profile_courses, :is_preview_claimed, :boolean
    add_index :course_profile_courses,
              [:catalog_offering_id, :is_preview, :is_preview_claimed],
              name: :preview_pending_indx
  end
end
