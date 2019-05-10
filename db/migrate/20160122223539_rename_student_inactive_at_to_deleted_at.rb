class RenameStudentInactiveAtToDeletedAt < ActiveRecord::Migration[4.2]
  def change
    rename_column :course_membership_students, :inactive_at, :deleted_at
  end
end
