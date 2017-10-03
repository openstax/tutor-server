class AddLastLmsScoresPushJobIdToCourseProfileCourses < ActiveRecord::Migration
  def change
    add_column :course_profile_courses, :last_lms_scores_push_job_id, :string
  end
end
