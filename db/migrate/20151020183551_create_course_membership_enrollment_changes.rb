class CreateCourseMembershipEnrollmentChanges < ActiveRecord::Migration
  def change
    create_table :course_membership_enrollment_changes do |t|
      t.references :user_profile,
                   null: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade },
                   index: true
      t.references :course_membership_period,
                   null: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade },
                   index: { name: 'index_course_membership_enrollment_changes_on_period_id' }
      t.integer :status, null: false, default: 0
      t.boolean :requires_enrollee_approval, null: false, default: true
      t.datetime :enrollee_approved_at

      t.timestamps null: false

      t.index [:user_profile_id, :created_at],
              name: 'index_course_membership_enrollment_changes_on_p_id_and_c_at', unique: true
    end
  end
end
