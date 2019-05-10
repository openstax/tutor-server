class CreateCourseMembershipEnrollments < ActiveRecord::Migration[4.2]
  def change
    create_table :course_membership_enrollments do |t|
      t.references :course_membership_period,
                   null: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :course_membership_student,
                   null: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }

      t.timestamps null: false

      t.index [:course_membership_student_id, :created_at],
              unique: true, name: 'course_membership_enrollments_student_created_at_uniq'
      t.index [:course_membership_period_id, :course_membership_student_id],
              name: 'course_membership_enrollments_period_student'
    end
  end
end
