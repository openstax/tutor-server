class AllowNullBiglearnAlgorithmNames < ActiveRecord::Migration[4.2]
  def change
    change_column_null :course_profile_courses, :biglearn_student_clues_algorithm_name, true
    change_column_null :course_profile_courses, :biglearn_teacher_clues_algorithm_name, true
    change_column_null :course_profile_courses, :biglearn_assignment_spes_algorithm_name, true
    change_column_null :course_profile_courses, :biglearn_assignment_pes_algorithm_name, true
    change_column_null :course_profile_courses, :biglearn_practice_worst_areas_algorithm_name, true

    reversible do |dir|
      dir.up do
        CourseProfile::Models::Course.update_all(
          biglearn_student_clues_algorithm_name: nil,
          biglearn_teacher_clues_algorithm_name: nil,
          biglearn_assignment_spes_algorithm_name: nil,
          biglearn_assignment_pes_algorithm_name: nil,
          biglearn_practice_worst_areas_algorithm_name: nil
        )
      end

      dir.down do
        CourseProfile::Models::Course.update_all(
          biglearn_student_clues_algorithm_name: Settings::Biglearn.student_clues_algorithm_name,
          biglearn_teacher_clues_algorithm_name: Settings::Biglearn.teacher_clues_algorithm_name,
          biglearn_assignment_spes_algorithm_name: \
            Settings::Biglearn.assignment_spes_algorithm_name,
          biglearn_assignment_pes_algorithm_name: \
            Settings::Biglearn.assignment_pes_algorithm_name,
          biglearn_practice_worst_areas_algorithm_name: \
            Settings::Biglearn.practice_worst_areas_algorithm_name
        )
      end
    end
  end
end
