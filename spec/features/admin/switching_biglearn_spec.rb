require 'rails_helper'
require 'vcr_helper'

RSpec.feature 'Switching biglearn option' do
  background do
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)

    # Have to explicitly disable stubbing to enable any non-fake client
    allow(Rails.application.secrets.openstax)
      .to receive(:[])
      .with('biglearn')
      .and_return (
        Rails.application.secrets.openstax['biglearn'].merge('stub' => false)
      )

    visit admin_rails_settings_ui_path
  end

  scenario 'Default client is local_query' do
    expect(page).to have_content(/Biglearn client/i)
    expect(find_field('settings_biglearn_client').value).to eq "local_query"
  end

  scenario 'by default, calls go to local query client' do
    expect(find_field('settings_biglearn_client').value).to eq "local_query"
    expect_any_instance_of(OpenStax::Biglearn::V1::LocalQueryClient).to receive(:get_clues)
    expect_any_instance_of(OpenStax::Biglearn::V1::RealClient).not_to receive(:get_clues)
    expect_any_instance_of(OpenStax::Biglearn::V1::FakeClient).not_to receive(:get_clues)
    OpenStax::Biglearn::V1.get_clues(roles: "blah", pools: "blah")
  end
# TODO need Local query to use fake client if BL stubbed
  scenario 'can change to real client' do
    select_field = find_field('settings_biglearn_client')
    expect(select_field.value).to eq "local_query"

    real_option = select_field.find(:xpath, 'option[2]')
    expect(real_option.value).to eq 'real'

    real_option.select_option
    click_button 'Save'

    Settings::Db.store.object('biglearn_client').rewrite_cache

    expect_any_instance_of(OpenStax::Biglearn::V1::RealClient).to receive(:get_clues)
    expect_any_instance_of(OpenStax::Biglearn::V1::LocalQueryClient).not_to receive(:get_clues)
    expect_any_instance_of(OpenStax::Biglearn::V1::FakeClient).not_to receive(:get_clues)
    OpenStax::Biglearn::V1.get_clues(roles: "blah", pools: "blah")
  end
end
