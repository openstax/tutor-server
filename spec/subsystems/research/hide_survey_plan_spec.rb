require 'rails_helper'

RSpec.describe Research::HideSurveyPlan do

  before(:each) do
    @course = FactoryBot.create :course_profile_course
    @period = FactoryBot.create :course_membership_period, course: @course

    @student_1_user = FactoryBot.create(:user)
    @student_2_user = FactoryBot.create(:user)

    @student_1 = AddUserAsPeriodStudent[period: @period, user: @student_1_user].student
    @student_2 = AddUserAsPeriodStudent[period: @period, user: @student_2_user].student

    @study = FactoryBot.create :research_study
    Research::AddCourseToStudy[course: @course, study: @study]
  end

  let(:survey_plan) { FactoryBot.create :research_survey_plan, study: @study }

  it "can hide survey plans" do
    Research::PublishSurveyPlan[survey_plan: survey_plan]

    [@student_1, @student_2].each do |student|
      expect(student.surveys.map(&:research_survey_plan_id)).to eq [survey_plan.id]
      expect(student.surveys.map(&:is_hidden?)).to eq [false]
    end

    described_class[survey_plan: survey_plan]

    expect(survey_plan.reload).to be_is_hidden
    expect(survey_plan.surveys.map(&:is_hidden?).uniq).to eq [true]
  end

end
