class RenameLmsCourseGradeCallbacksToUseScore < ActiveRecord::Migration
  def change
    rename_table :lms_course_grade_callbacks, :lms_course_score_callbacks

    rename_index :lms_course_score_callbacks,
                 :course_grade_callbacks_on_course_user_result_outcome,
                 :course_score_callbacks_on_course_user_result_outcome

    rename_index :lms_course_score_callbacks,
                 :course_grade_callback_result_outcome,
                 :course_score_callback_result_outcome

    rename_index :lms_course_score_callbacks,
                 :course_grade_callbacks_on_user,
                 :course_score_callbacks_on_user
  end
end
