class CreateCourseMembershipStudents < ActiveRecord::Migration
  def change
    create_table :course_membership_students do |t|
      t.integer :entity_course_id, null: false
      t.integer :entity_role_id,   null: false
      t.timestamps null: false

      t.index [:entity_course_id, :entity_role_id], unique: true, name: 'course_membership_student_course_role_uniq'
    end

     add_foreign_key :course_membership_students, :entity_courses
     add_foreign_key :course_membership_students, :entity_roles
  end
end
