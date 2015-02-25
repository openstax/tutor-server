class CreateCourseSsTeachers < ActiveRecord::Migration
  def change
    create_table :course_ss_teachers do |t|
      t.integer :entity_ss_course_id, null: false
      t.integer :entity_ss_role_id,   null: false
      t.timestamps null: false

      t.index [:entity_ss_course_id, :entity_ss_role_id], unique: true, name: 'course_ss_teacher_course_role_uniqueness'
    end
  end
end
