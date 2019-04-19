class CreateCourseMembershipTeacherStudents < ActiveRecord::Migration
  def change
    create_table :course_membership_teacher_students do |t|
      t.references :course_profile_course,
                   null: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :entity_role,
                   null: false,
                   index: { unique: true },
                   foreign_key: { on_update: :cascade, on_delete: :cascade }

      t.timestamps null: false
    end
  end
end
