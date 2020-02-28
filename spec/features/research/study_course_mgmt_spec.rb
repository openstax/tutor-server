require 'rails_helper'
require 'feature_js_helper'

RSpec.feature 'Study Course Management', js: true do

  before do
    researcher = FactoryBot.create(:user_profile, :researcher)
    stub_current_user(researcher)
  end

  let!(:study) { Research::Models::Study.create(name: "A Study") }

  context 'adding courses' do
    before { allow(Research::StudiesController).to receive(:default_per_page) { 2 } }

    scenario 'add one course' do
      course = FactoryBot.create :course_profile_course
      visit research_study_path(study)
      click_button 'Search'
      click_add
      expect(study.courses).to include(course)
    end

    context "multiple courses available" do
      let!(:driving_courses) do
        3.times.map { |ii| FactoryBot.create :course_profile_course, name: "Driving #{ii}" }
      end
      let!(:running_courses) do
        3.times.map { |ii| FactoryBot.create :course_profile_course, name: "Running #{ii}" }
      end

      context "search for Driving" do
        let(:search_query) { "Driving" }

        before do
          visit research_study_path(study)
          fill_in 'query', with: search_query
          click_button 'Search'
        end

        scenario "select all across pages works" do
          check 'courses_select_all_on_all_pages'
          expect(page).to have_selector('.stats-card', count: 2)
          click_add
          expect(study.courses.count).to eq 3
        end

        scenario "unclicking select all unselects across all pages" do
          uncheck 'courses_select_all_on_page'
          click_add
          expect(study.courses.count).to eq 0
        end
      end
    end

    scenario 're-adding an existing course works with notification' do
      course = FactoryBot.create :course_profile_course
      Research::AddCourseToStudy[course: course, study: study]
      visit research_study_path(study)
      click_button 'Search'
      click_add
      expect(page).to have_content(/1 courses not added/)
      expect(study.courses).to include(course)
    end
  end

  context 'removing courses' do
    before do
      @course = FactoryBot.create :course_profile_course
      FactoryBot.create(:research_survey_plan, :published, study: study)
      Research::AddCourseToStudy[course: @course, study: study]
    end

    scenario 'study never active' do
      period = FactoryBot.create :course_membership_period, course: @course

      3.times do
        role = FactoryBot.create :entity_role
        CourseMembership::AddStudent[period: period, role: role]
      end

      # Students in cohorts with surveys
      expect(study.cohorts.flat_map(&:cohort_members)).not_to be_empty
      expect(study.survey_plans.flat_map(&:surveys).count).to eq 3

      visit research_study_path(study)
      click_link 'Remove'
      alert.accept
      wait_for_ajax

      # Students no longer in cohorts and surveys gone
      expect(study.courses).to be_empty
      expect(study.cohorts.reload.flat_map(&:cohort_members)).to be_empty
      expect(study.survey_plans.map { |sp| sp.surveys.without_deleted.count }.sum).to eq 0
      expect(page).not_to have_link 'Remove'
    end

    scenario 'study active' do
      Research::ActivateStudy[study]
      visit research_study_path(study)
      expect(page).not_to have_link 'Remove'
    end
  end

  def click_add
    click_button 'Add selected courses to study (can be slow)'
  end

end
