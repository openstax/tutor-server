class CreateCourseMembershipEnrollments < ActiveRecord::Migration
  def change
    create_table :course_membership_enrollments do |t|
      t.references :course_membership_period,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :course_membership_student,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.datetime   :inactive_at

      t.timestamps null: false

      t.index [:course_membership_period_id, :course_membership_student_id],
              unique: true, name: 'course_membership_enrollments_period_student_uniq'
      t.index [:course_membership_student_id, :created_at],
              unique: true, name: 'course_membership_enrollments_student_created_at_uniq'
    end
  end
end
