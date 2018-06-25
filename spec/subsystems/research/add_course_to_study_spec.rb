require 'rails_helper'

RSpec.describe Research::AddCourseToStudy do

  before(:each) do
    @course = FactoryBot.create :course_profile_course
    @period = FactoryBot.create :course_membership_period, course: @course

    @student_1_user = FactoryBot.create(:user)
    @student_2_user = FactoryBot.create(:user)

    @student_1 = AddUserAsPeriodStudent[period: @period, user: @student_1_user].student
    @student_2 = AddUserAsPeriodStudent[period: @period, user: @student_2_user].student

    @study = FactoryBot.create :research_study
  end

  let(:survey_plan) { FactoryBot.create :research_survey_plan, study: @study }

  it "adds the course to the study" do
    described_class[study: @study, course: @course]
    expect(@study.courses(true)).to include(@course)
    expect(@course.studies(true)).to include(@study)
  end

  it "freaks out if course already in study" do
    described_class[study: @study, course: @course]
    expect{
      described_class[study: @study, course: @course]
    }.to raise_error(StandardError)
  end

  it "assigns previously-published surveys to course students" do
    survey_plan = FactoryBot.create :research_survey_plan, :published, study: @study
    described_class[study: @study, course: @course]

    [@student_1, @student_2].each do |student|
      expect(student.surveys.map(&:research_survey_plan_id)).to eq [survey_plan.id]
    end
  end

  it "does not assign unpublished surveys to course students" do
    survey_plan = FactoryBot.create :research_survey_plan, study: @study
    described_class[study: @study, course: @course]

    [@student_1, @student_2].each do |student|
      expect(student.surveys).to be_empty
    end
  end

  it "does not change assignment for students who already have it" do
    # Distribute survey to 1st course
    survey_plan = FactoryBot.create :research_survey_plan, :published, study: @study
    described_class[study: @study, course: @course]

    # Add a new course to the study...
    another_course = FactoryBot.create :course_profile_course
    another_period = FactoryBot.create :course_membership_period, course: another_course
    student_3_user = FactoryBot.create(:user)
    student_3 = AddUserAsPeriodStudent[period: another_period, user: student_3_user].student

    # It should not mess with students 1 and 2, but should add survey to student 3
    expect{
      described_class[study: @study, course: another_course]
    }.to change{ Research::Models::Survey.count }.by(1)

    [@student_1, @student_2, student_3].each do |student|
      expect(student.surveys.map(&:research_survey_plan_id)).to eq [survey_plan.id]
    end
  end

end
