require 'rails_helper'

RSpec.describe Research::UnhideSurveyPlan do

  before(:each) do
    @course = FactoryBot.create :course_profile_course
    @period = FactoryBot.create :course_membership_period, course: @course

    @student_1_user = FactoryBot.create(:user_profile)
    @student_2_user = FactoryBot.create(:user_profile)

    @student_1 = AddUserAsPeriodStudent[period: @period, user: @student_1_user].student
    @student_2 = AddUserAsPeriodStudent[period: @period, user: @student_2_user].student

    @study = FactoryBot.create :research_study
    Research::AddCourseToStudy[course: @course, study: @study]
  end

  let(:survey_plan) { FactoryBot.create :research_survey_plan, study: @study }

  it "can unhide survey plans" do
    Research::PublishSurveyPlan[survey_plan: survey_plan]

    [@student_1, @student_2].each do |student|
      expect(student.surveys.map(&:research_survey_plan_id)).to eq [survey_plan.id]
      expect(student.surveys.map(&:is_hidden?)).to eq [false]
    end

    Research::HideSurveyPlan[survey_plan: survey_plan]

    student_3_user = FactoryBot.create(:user_profile)
    student_3 = AddUserAsPeriodStudent[period: @period, user: student_3_user].student

    # This student shouldn't get the survey since it is now hidden
    expect(student_3.surveys).to be_empty

    # Unhide
    described_class[survey_plan: survey_plan]

    expect(survey_plan.reload).not_to be_is_hidden
    expect(survey_plan.surveys.map(&:is_hidden?).uniq).to eq [false]

    # Student 3 should get the survey when it is unhidden since it is published
    expect(student_3.surveys.count).to eq 1
  end

end
