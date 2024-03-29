require 'rails_helper'
require 'feature_js_helper'

RSpec.feature 'Cohorts', js: true do

  before do
    researcher = FactoryBot.create(:user_profile, :researcher)
    stub_current_user(researcher)
  end

  let!(:study) { Research::Models::Study.create(name: "A Study") }

  context 'when study inactive' do

    scenario 'can add a cohort' do
      visit research_study_path(study)

      click_link 'Add new cohort'
      fill_in 'Name', with: 'AAA'
      click_button 'Save'

      expect(page).to have_content(/Cohorts:.*AAA \/ 0 Members/m)
    end
  end

  context "when study active" do
    before { Research::ActivateStudy[study] }

    scenario "cannot add a cohort" do
      visit research_study_path(study)
      expect(page).not_to have_link('Add new cohort')
    end
  end

  context "cohort exists" do
    let!(:cohort) { Research::Models::Cohort.create(name: "AAA", study: study) }

    scenario "can navigate to cohort and back to study" do
      visit research_study_path(study)
      click_link "AAA"
      click_link "A Study"
      expect(page).to have_current_path(research_study_path(study))
    end

    scenario 'can change name of a cohort' do
      visit research_study_path(study)
      click_link "AAA"
      click_link "Edit"
      fill_in 'Name', with: 'BBB'
      click_button 'Save'
      wait_for_ajax
      expect(page).to have_content(/Name: BBB/)
    end

    scenario 'can change is_accepting_members' do
      visit research_study_path(study)
      click_link "AAA"
      click_link "Edit"
      uncheck 'research_models_cohort_is_accepting_members'
      click_button 'Save'
      expect(page).to have_content(/Accepting new members: false/)
    end

    context 'when there are members' do
      scenario 'can redistribute them to other cohorts' do
        3.times do
          Research::Models::CohortMember.create(
            cohort: cohort,
            student: FactoryBot.create(:course_membership_student)
          )
        end

        Research::Models::Cohort.create(name: "BBB", study: study)
        Research::Models::Cohort.create(name: "CCC", study: study)

        visit research_study_path(study)
        click_link "AAA"
        click_link 'Reassign Members'
        alert.accept
        expect(page).to have_content(/Success/)
        click_link 'A Study'
        expect(page).to have_content(/0 Members/)
        expect(page).to have_content(/2 Members/)
        expect(page).to have_content(/1 Members/)
      end
    end

    context 'when there are no members' do
      scenario 'can delete a cohort' do
        visit research_study_path(study)
        expect(page).to have_content(/AAA \//)
        click_link "AAA"
        click_link "Delete"
        alert.accept
        expect(page).to have_content(/Cohorts:/)
        expect(page).not_to have_content(/AAA \//)
      end
    end

    scenario 'shows count of students in each cohort' do
      Research::Models::CohortMember.create(cohort: cohort, student: FactoryBot.create(:course_membership_student))
      visit research_study_path(study)
      expect(page).to have_content("1 Member")
    end
  end

end
