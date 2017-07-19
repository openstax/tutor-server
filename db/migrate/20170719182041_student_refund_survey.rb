class StudentRefundSurvey < ActiveRecord::Migration
  def change
    add_column :course_membership_students, :refund_survey_response, :jsonb, default: '{}'
  end
end
