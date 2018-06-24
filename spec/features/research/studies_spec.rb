require 'rails_helper'
require 'feature_js_helper'

RSpec.feature 'Studies', js: true do

  before do
    researcher = FactoryBot.create(:user, :researcher)
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

      expect(page).to have_content(/Something else.*Inactive.*Delete/)
    end

    context 'inactive' do
      scenario 'delete' do
        visit research_studies_path
        expect(page).to have_content(/A Study.*Inactive.*Delete/)
        click_link 'Delete'
        alert.accept
        expect(page).not_to have_content(/A Study.*Inactive.*Delete/)
      end
    end

    context 'active' do
      scenarion 'delete' do

      end

    end
  end

end
