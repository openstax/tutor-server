class CreateCourseMembershipStudents < ActiveRecord::Migration
  def change
    create_table :course_membership_students do |t|
      t.integer :course_membership_period_id, null: false
      t.integer :entity_role_id,   null: false
      t.string :deidentifier, null: false
      t.timestamps null: false

      t.index [:course_membership_period_id, :entity_role_id],
              unique: true, name: 'course_membership_student_period_role_uniq'
      t.index :deidentifier, unique: true
    end

     add_foreign_key :course_membership_students, :course_membership_periods
     add_foreign_key :course_membership_students, :entity_roles
  end
end
