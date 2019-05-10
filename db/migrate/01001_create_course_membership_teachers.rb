class CreateCourseMembershipTeachers < ActiveRecord::Migration[4.2]
  def change
    create_table :course_membership_teachers do |t|
      t.references :entity_course,
                   null: false,
                   index: true,
                   foreign_key: { on_update: :cascade,  on_delete: :cascade }
      t.references :entity_role,
                   null: false,
                   index: { unique: true },
                   foreign_key: { on_update: :cascade, on_delete: :cascade }

      t.timestamps null: false
    end
  end
end
