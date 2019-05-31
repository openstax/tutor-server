class CreateCourseMembershipTeacherStudents < ActiveRecord::Migration[4.2]
  def change
    create_table :course_membership_teacher_students do |t|
      t.references :course_profile_course,
                   null: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :course_membership_period,
                   null: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :entity_role,
                   null: false,
                   index: { unique: true },
                   foreign_key: { on_update: :cascade, on_delete: :cascade }

      t.uuid :uuid, null: false, default: 'gen_random_uuid()', index: { unique: true }

      t.datetime :deleted_at

      t.timestamps null: false
    end

    reversible do |dir|
      dir.up { Entity::Role.teacher_student.delete_all }

      dir.down do
        CourseMembership::Models::Period.find_each do |period|
          role = Entity::Role.create! role_type: :teacher_student
          period.update_attribute :entity_teacher_student_role_id, role.id
        end

        change_column_null :course_membership_periods, :entity_teacher_student_role_id, false
      end
    end

    remove_column :course_membership_periods, :entity_teacher_student_role_id, :integer

    add_index :course_membership_students, :course_membership_period_id
    add_index :course_membership_teacher_students, :course_profile_course_id,
              name: 'index_teacher_students_on_course_id'
    add_index :course_membership_teacher_students, :course_membership_period_id,
              name: 'index_teacher_students_on_period_id'
  end
end
