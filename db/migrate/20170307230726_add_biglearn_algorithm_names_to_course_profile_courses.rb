class AddBiglearnAlgorithmNamesToCourseProfileCourses < ActiveRecord::Migration[4.2]
  def up
    add_column :course_profile_courses, :biglearn_student_clues_algorithm_name, :string
    add_column :course_profile_courses, :biglearn_teacher_clues_algorithm_name, :string
    add_column :course_profile_courses, :biglearn_assignment_spes_algorithm_name, :string
    add_column :course_profile_courses, :biglearn_assignment_pes_algorithm_name, :string
    add_column :course_profile_courses, :biglearn_practice_worst_areas_algorithm_name, :string

    reversible do |dir|
      dir.up do
        change_column_null :course_profile_courses,
                           :biglearn_student_clues_algorithm_name,
                           false
        change_column_null :course_profile_courses,
                           :biglearn_teacher_clues_algorithm_name,
                           false
        change_column_null :course_profile_courses,
                           :biglearn_assignment_spes_algorithm_name,
                           false
        change_column_null :course_profile_courses,
                           :biglearn_assignment_pes_algorithm_name,
                           false
        change_column_null :course_profile_courses,
                           :biglearn_practice_worst_areas_algorithm_name,
                           false
      end
    end
  end
end
