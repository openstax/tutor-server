require 'rails_helper'
require 'feature_js_helper'

RSpec.feature 'Cohorts', js: true do

  before do
    researcher = FactoryBot.create(:user, :researcher)
    stub_current_user(researcher)
  end

  let!(:study) { Research::Models::Study.create(name: "A Study") }

  xscenario 'default cohort and add cohort link present' do
    visit research_study_path(study)

    # click_link 'Add Study'
    # fill_in 'Name', with: 'A Study'
    # click_button 'Save'

    # expect(page).to have_content(/A Study.*Inactive.*Delete/)
  end

  xscenario 'can change name of default cohort' do

  end

  context 'under certain conditions' do
    xscenario 'can add a new cohort' do

    end
  end

  context 'under certain conditions' do
    xscenario 'can delete a cohort' do

    end
  end

  xscenario 'shows count of students in each cohort' do

  end


end
