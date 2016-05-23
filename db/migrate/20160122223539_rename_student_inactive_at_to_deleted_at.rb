class RenameStudentInactiveAtToDeletedAt < ActiveRecord::Migration
  def change
    rename_column :course_membership_students, :inactive_at, :deleted_at
  end
end
