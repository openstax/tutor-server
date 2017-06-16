require 'rails_helper'
require 'vcr_helper'

RSpec.feature 'Switching biglearn option' do
  before(:all) do
    @student = FactoryGirl.create :course_membership_student
    @book_container = FactoryGirl.create :content_page
  end

  let(:request_uuid) { SecureRandom.uuid }
  let(:request)      do
    { request_uuid: request_uuid, student: @student, book_container: @book_container }
  end
  let(:responses)    { [ { request_uuid: request_uuid, clue_data: {} } ] }

  background do
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)

    visit admin_rails_settings_ui_path
  end

  scenario 'in test env, calls go to fake client by default' do
    expect(page).to have_content(/Biglearn client/i)
    expect(find_field('settings_biglearn_client_name').value).to eq 'fake'

    expect_any_instance_of(OpenStax::Biglearn::Api::FakeClient).to(
      receive(:fetch_student_clues)
    ).and_call_original
    expect_any_instance_of(OpenStax::Biglearn::Api::RealClient).not_to receive(:fetch_student_clues)

    OpenStax::Biglearn::Api.fetch_student_clues(request)
  end

  scenario 'can change to real client' do
    select_field = find_field('settings_biglearn_client_name')
    expect(select_field.value).to eq 'fake'

    real_option = select_field.find('[value=real]')
    expect(real_option.value).to eq 'real'

    real_option.select_option

    begin
      click_button 'Save'

      # Expire the cached setting so we can see the change
      expire_biglearn_client_name_settings_cache

      expect_any_instance_of(OpenStax::Biglearn::Api::RealClient).to(
        receive(:fetch_student_clues)
      ).and_return(responses)
      expect_any_instance_of(OpenStax::Biglearn::Api::FakeClient).not_to(
        receive(:fetch_student_clues)
      )

      OpenStax::Biglearn::Api.fetch_student_clues(request)
    ensure
      # Prevent other specs from being affected by this one
      Settings::Db.store.biglearn_client_name = 'fake'

      expire_biglearn_client_name_settings_cache
    end
  end

  def expire_biglearn_client_name_settings_cache
    Settings::Db.store.object('biglearn_client_name').try!(:expire_cache)

    RequestStore.clear!
  end
end
