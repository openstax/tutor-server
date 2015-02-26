class CreateCourseMembershipTeachers < ActiveRecord::Migration
  def change
    create_table :course_membership_teachers do |t|
      t.integer :entity_course_id, null: false
      t.integer :entity_role_id,   null: false
      t.timestamps null: false

      t.index [:entity_course_id, :entity_role_id], unique: true, name: 'course_membership_teacher_course_role_uniq'
    end

     add_foreign_key :course_membership_teachers, :entity_courses
     add_foreign_key :course_membership_teachers, :entity_roles
  end
end
