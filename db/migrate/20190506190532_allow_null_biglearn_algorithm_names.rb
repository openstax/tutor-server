class AllowNullBiglearnAlgorithmNames < ActiveRecord::Migration[4.2]
  def change
    change_column_null :course_profile_courses, :biglearn_student_clues_algorithm_name, true
    change_column_null :course_profile_courses, :biglearn_teacher_clues_algorithm_name, true
    change_column_null :course_profile_courses, :biglearn_assignment_spes_algorithm_name, true
    change_column_null :course_profile_courses, :biglearn_assignment_pes_algorithm_name, true
    change_column_null :course_profile_courses, :biglearn_practice_worst_areas_algorithm_name, true
  end
end
