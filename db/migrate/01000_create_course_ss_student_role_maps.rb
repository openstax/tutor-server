class CreateCourseSsStudentRoleMaps < ActiveRecord::Migration
  def change
    create_table :course_ss_student_role_maps do |t|
      t.integer :entity_ss_course_id, null: false
      t.integer :entity_ss_role_id,   null: false
      t.timestamps null: false

      t.index [:entity_ss_course_id, :entity_ss_role_id], unique: true, name: 'entity_ss_course_id_role_id_uniqueness'
    end
  end
end
