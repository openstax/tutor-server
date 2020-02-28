require 'rails_helper'

RSpec.feature 'Researcher working with survey plans' do
  background do
    @course = FactoryBot.create :course_profile_course
    @period = FactoryBot.create :course_membership_period, course: @course

    @student_1_user = FactoryBot.create(:user_profile)
    @student_2_user = FactoryBot.create(:user_profile)

    @student_1 = AddUserAsPeriodStudent[period: @period, user: @student_1_user].student
    @student_2 = AddUserAsPeriodStudent[period: @period, user: @student_2_user].student

    @study = FactoryBot.create :research_study, name: "Study 1"
    Research::AddCourseToStudy[course: @course, study: @study]

    researcher = FactoryBot.create(:user_profile, :researcher)
    stub_current_user(researcher)
  end

  scenario 'view console' do
    visit research_root_path
    expect(page).to have_content('Research Console')
  end

  scenario 'add a survey plan' do
    visit research_survey_plans_path
    click_link 'Add Survey Plan'
    fill_in 'Title for researchers', with: 'Title for researchers'
    fill_in 'Title for students', with: 'Title for students'
    fill_in 'Survey js model', with: FactoryBot.build(:research_survey_plan).survey_js_model
    click_button 'Save'
    expect(page).to have_content("Survey Plan was successfully created.")
    expect(page).to have_content(/Title for researchers.*Study 1.*Draft.*Edit.*Preview.*Publish.*Hide/)
  end

  scenario 'publish a survey plan' do
    survey_plan = FactoryBot.create :research_survey_plan, study: @study
    visit research_survey_plans_path
    click_link 'Publish'
    expect(page).to have_content(/Published survey plan/)
    expect(survey_plan.surveys.count).to eq 2
    expect(page).to have_content("Published")
  end

  scenario 'hide an unpublished survey plan' do
    survey_plan = FactoryBot.create :research_survey_plan, study: @study
    visit research_survey_plans_path
    click_link 'Hide'
    expect(survey_plan.reload).to be_is_hidden
    expect(page).to have_content(/Hid survey plan/)
    expect(page).to have_content("Draft / Hidden")
    expect(page).not_to have_content("Publish")
  end

  scenario 'hide a published survey plan' do
    survey_plan = FactoryBot.create :research_survey_plan, study: @study
    visit research_survey_plans_path
    click_link 'Publish'
    click_link 'Hide'
    expect(survey_plan.reload).to be_is_hidden
    expect(survey_plan.surveys.all?(&:is_hidden?)).to eq true
  end

  scenario 'hide a published survey plan' do
    survey_plan = FactoryBot.create :research_survey_plan, study: @study
    visit research_survey_plans_path
    click_link 'Publish'
    click_link 'Hide'
    expect(survey_plan.reload).to be_is_hidden
    expect(survey_plan.surveys.all?(&:is_hidden?)).to eq true
  end

  scenario 'export a published survey plan' do
    survey_plan = FactoryBot.create :research_survey_plan, study: @study
    expect(Research::ExportAndUploadSurveyData).to(
      receive(:perform_later).with(survey_plan: survey_plan, filename: kind_of(String))
    )
    visit research_survey_plans_path
    click_link 'Publish'
    click_link 'Export'
  end

end
