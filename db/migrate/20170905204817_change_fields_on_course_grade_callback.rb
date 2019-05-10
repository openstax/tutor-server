class ChangeFieldsOnCourseGradeCallback < ActiveRecord::Migration[4.2]
  def change
    remove_index :lms_course_grade_callbacks, name: :course_grade_callbacks_on_student
    remove_reference :lms_course_grade_callbacks, :course_membership_student

    add_reference :lms_course_grade_callbacks, :user_profile, null: false,
                  index: { name: :course_grade_callbacks_on_user },
                  foreign_key: { on_update: :cascade, on_delete: :cascade }

    add_reference :lms_course_grade_callbacks, :course_profile_course, null: false,
                  foreign_key: { on_update: :cascade, on_delete: :cascade }

    add_index :lms_course_grade_callbacks,
              [:course_profile_course_id, :user_profile_id, :result_sourcedid, :outcome_url],
              name: :course_grade_callbacks_on_course_user_result_outcome
  end
end
