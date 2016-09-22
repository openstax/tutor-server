require 'rails_helper'
require 'vcr_helper'

RSpec.feature 'Switching biglearn option' do
  background do
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)

    visit admin_rails_settings_ui_path
  end

  xscenario 'in test env, calls go to fake client by default' do
    expect(page).to have_content(/Biglearn client/i)
    expect(find_field('settings_biglearn_client').value).to eq "fake"

    expect_any_instance_of(OpenStax::Biglearn::Api::FakeClient).to receive(:get_clues)
    expect_any_instance_of(OpenStax::Biglearn::Api::LocalQueryClient).not_to receive(:get_clues)
    expect_any_instance_of(OpenStax::Biglearn::Api::RealClient).not_to receive(:get_clues)

    OpenStax::Biglearn::Api.get_clues(roles: "blah", pools: "blah")
  end

  xscenario 'can change to real client' do
    select_field = find_field('settings_biglearn_client')
    expect(select_field.value).to eq "fake"

    real_option = select_field.find(:xpath, 'option[3]')
    expect(real_option.value).to eq 'real'

    real_option.select_option
    click_button 'Save'

    expect_any_instance_of(OpenStax::Biglearn::Api::RealClient).to receive(:get_clues)
    expect_any_instance_of(OpenStax::Biglearn::Api::LocalQueryClient).not_to receive(:get_clues)
    expect_any_instance_of(OpenStax::Biglearn::Api::FakeClient).not_to receive(:get_clues)
    OpenStax::Biglearn::Api.get_clues(roles: "blah", pools: "blah")

    Settings::Db.store.biglearn_client = :fake
  end
end
