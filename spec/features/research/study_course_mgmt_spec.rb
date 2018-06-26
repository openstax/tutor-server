require 'rails_helper'
require 'feature_js_helper'

RSpec.feature 'Study Course Management', js: true do

  before do
    researcher = FactoryBot.create(:user, :researcher)
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
      expect(study.courses(true)).to include(course)
    end

    context "multiple courses available" do
      let!(:driving_courses) { 3.times.map{|ii| FactoryBot.create :course_profile_course, name: "Driving #{ii}"} }
      let!(:running_courses) { 3.times.map{|ii| FactoryBot.create :course_profile_course, name: "Running #{ii}"} }

      context "search for Driving" do
        let(:search_query) { "Driving" }

        before {
          visit research_study_path(study)
          fill_in 'query', with: search_query
          click_button 'Search'
        }

        scenario "select all across pages works" do
          check 'courses_select_all_on_all_pages'
          expect(page).to have_selector('.stats-card', count: 2)
          click_add
          expect(study.courses(true).count).to eq 3
        end

        scenario "unclicking select all unselects across all pages" do
          uncheck 'courses_select_all_on_page'
          click_add
          expect(study.courses(true).count).to eq 0
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
      expect(study.courses(true)).to include(course)
    end
  end

  context 'removing courses' do
    scenario 'study inactive' do

    end

    scenario 'study active' do

    end
  end

  def click_add
    click_button 'Add selected courses to study (can be slow)'
  end

end
