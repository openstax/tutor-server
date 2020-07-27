class RemoveBiglearnColumns < ActiveRecord::Migration[5.2]
  def up
    remove_column :content_ecosystems, :sequence_number

    remove_column :course_profile_courses, :sequence_number
    remove_column :course_profile_courses, :biglearn_student_clues_algorithm_name
    remove_column :course_profile_courses, :biglearn_teacher_clues_algorithm_name
    remove_column :course_profile_courses, :biglearn_assignment_spes_algorithm_name
    remove_column :course_profile_courses, :biglearn_assignment_pes_algorithm_name
    remove_column :course_profile_courses, :biglearn_practice_worst_areas_algorithm_name
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
