class AddBiglearnAlgorithmNamesToCourseProfileCourses < ActiveRecord::Migration
  def up
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

    # Remove local_query_with_ from the default biglearn client, since those are no longer valid
    biglearn_client = Settings::Db.store.biglearn_client
    Settings::Db.store.biglearn_client = biglearn_client.to_s.sub('local_query_with_', '').to_sym
  end

  def down
    remove_column :course_profile_courses, :biglearn_practice_worst_areas_algorithm_name, :string
    remove_column :course_profile_courses, :biglearn_assignment_pes_algorithm_name, :string
    remove_column :course_profile_courses, :biglearn_assignment_spes_algorithm_name, :string
    remove_column :course_profile_courses, :biglearn_teacher_clues_algorithm_name, :string
    remove_column :course_profile_courses, :biglearn_student_clues_algorithm_name, :string
  end
end
