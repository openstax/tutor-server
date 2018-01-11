require 'rails_helper'

RSpec.describe Research::PublishSurveyPlan do

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

  context "when already published" do
    it "freaks out" do
      expect{described_class[survey_plan: survey_plan]}.not_to raise_error
      expect{described_class[survey_plan: survey_plan]}.to raise_error(/already-published/)
    end
  end

  context "when not yet published" do
    it "becomes marked as published" do
      described_class[survey_plan: survey_plan]
      expect(survey_plan.reload).to be_is_published
    end

    it "assigns to students missing it" do
      described_class[survey_plan: survey_plan]

      [@student_1, @student_2].each do |student|
        expect(student.surveys.map(&:research_survey_plan_id)).to eq [survey_plan.id]
      end
    end
  end

end
