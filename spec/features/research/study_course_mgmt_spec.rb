require 'rails_helper'
require 'feature_js_helper'

RSpec.feature 'Study Course Management', js: true do

  before do
    researcher = FactoryBot.create(:user, :researcher)
    stub_current_user(researcher)
  end

  let!(:study) { Research::Models::Study.create(name: "A Study") }

  context 'adding courses' do
    scenario 'happy path' do

    end

    scenario 're-adding an existing course' do

    end
  end

  context 'removing courses' do
    scenario 'study inactive' do

    end

    scenarion 'study active' do

    end
  end

end
