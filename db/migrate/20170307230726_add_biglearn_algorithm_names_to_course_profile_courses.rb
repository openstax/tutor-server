class AddBiglearnAlgorithmNamesToCourseProfileCourses < ActiveRecord::Migration
  def change
    add_column :course_profile_courses, :biglearn_student_clues_algorithm_name, :string
    add_column :course_profile_courses, :biglearn_teacher_clues_algorithm_name, :string
    add_column :course_profile_courses, :biglearn_assignment_spes_algorithm_name, :string
    add_column :course_profile_courses, :biglearn_assignment_pes_algorithm_name, :string
    add_column :course_profile_courses, :biglearn_practice_worst_areas_algorithm_name, :string

    change_column_null :course_profile_courses,
                       :biglearn_student_clues_algorithm_name,
                       false,
                       Settings::Biglearn.student_clues_algorithm_name
    change_column_null :course_profile_courses,
                       :biglearn_teacher_clues_algorithm_name,
                       false,
                       Settings::Biglearn.teacher_clues_algorithm_name
    change_column_null :course_profile_courses,
                       :biglearn_assignment_spes_algorithm_name,
                       false,
                       Settings::Biglearn.assignment_spes_algorithm_name
    change_column_null :course_profile_courses,
                       :biglearn_assignment_pes_algorithm_name,
                       false,
                       Settings::Biglearn.assignment_pes_algorithm_name
    change_column_null :course_profile_courses,
                       :biglearn_practice_worst_areas_algorithm_name,
                       false,
                       Settings::Biglearn.practice_worst_areas_algorithm_name
  end
end
