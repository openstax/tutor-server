class CreateCourseMembershipEnrollmentChanges < ActiveRecord::Migration[4.2]
  def change
    create_table :course_membership_enrollment_changes do |t|
      t.references :user_profile,
                   null: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade },
                   index: true
      t.references :course_membership_enrollment,
                   foreign_key: { on_update: :cascade, on_delete: :nullify },
                   index: {
                     name: 'index_course_membership_enrollments_on_enrollment_id', unique: true
                   }
      t.references :course_membership_period,
                   null: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade },
                   index: { name: 'index_course_membership_enrollment_changes_on_period_id' }
      t.integer :status, null: false, default: 0
      t.boolean :requires_enrollee_approval, null: false, default: true
      t.datetime :enrollee_approved_at

      t.timestamps null: false
    end
  end
end
