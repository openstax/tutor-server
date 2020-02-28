require 'rails_helper'
require 'feature_js_helper'

RSpec.feature 'Studies', js: true do

  before do
    researcher = FactoryBot.create(:user_profile, :researcher)
    stub_current_user(researcher)
  end

  scenario 'add a study' do
    visit research_studies_path

    click_link 'Add Study'
    fill_in 'Name', with: 'A Study'
    click_button 'Save'

    expect(page).to have_content(/A Study.*Inactive.*Delete/)
  end

  context 'existing study' do
    let!(:study) { Research::Models::Study.create(name: "A Study") }

    scenario 'rename' do
      visit research_studies_path

      click_link 'A Study'
      click_link 'Edit'
      fill_in 'Name', with: 'Something else'
      click_button 'Save'

      expect(page).to have_content(/Something else \(ID/)
    end

    context 'inactive' do
      scenario 'delete' do
        visit research_studies_path
        expect(page).to have_content(/A Study.*Inactive.*Delete/)
        click_link 'Delete'
        alert.accept
        expect(page).not_to have_content(/A Study.*Inactive.*Delete/)
      end

      scenario 'activate it' do
        visit research_study_path(study)
        click_link 'Activate'
        alert.accept
        expect(page).to have_content(/ activated!/)
        expect(page).to have_content(/| Active |/)
        expect(study.reload).to be_active
      end
    end

    context 'active' do
      before { Research::ActivateStudy[study] }

      scenario 'delete' do
        visit research_studies_path
        expect(page).to have_content(/A Study.*Active.*Delete/)
        click_link 'Delete'
        alert.accept
        expect(page).to have_content(/Cannot destroy an active study/)
      end

      scenario 'activate it' do
        visit research_study_path(study)
        click_link 'Deactivate'
        alert.accept
        expect(page).to have_content(/deactivated!/)
        expect(page).to have_content(/| Inactive |/)
        expect(study.reload).not_to be_active
      end
    end
  end

end
