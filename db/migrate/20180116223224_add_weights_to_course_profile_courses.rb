class AddWeightsToCourseProfileCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :course_profile_courses, :homework_score_weight, :decimal, precision: 3, scale: 2,
                                                                          null: false, default: 1
    add_column :course_profile_courses, :homework_progress_weight, :decimal, precision: 3, scale: 2,
                                                                             null: false, default: 0
    add_column :course_profile_courses, :reading_score_weight, :decimal, precision: 3, scale: 2,
                                                                         null: false, default: 0
    add_column :course_profile_courses, :reading_progress_weight, :decimal, precision: 3, scale: 2,
                                                                            null: false, default: 0
  end
end
