class CreateCourseMembershipStudents < ActiveRecord::Migration
  def change
    create_table :course_membership_students do |t|
      t.references :entity_course,
                   null: false,
                   foreign_key: { on_update: :cascade,  on_delete: :cascade }
      t.references :entity_role,
                   null: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.string :deidentifier, null: false, index: { unique: true }
      t.datetime   :inactive_at

      t.timestamps null: false

      t.index [:entity_role_id, :entity_course_id],
              unique: true, name: 'course_membership_students_role_course_uniq'
      t.index [:entity_course_id, :inactive_at], name: 'course_membership_students_course_inactive'
    end
  end
end
