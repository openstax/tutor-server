require 'rails_helper'

RSpec.describe Api::V1::BootstrapDataRepresenter, type: :representer do

  let(:user)           { FactoryBot.create(:user) }
  let(:representation) do
    described_class.new(user).to_json(
      user_options: {
        tutor_api_url: 'https://example.com/api',
        flash: { alert: 'Nothing!'}
      }
    )
  end

  it "generates a JSON representation of data for a user to start work with" do
    expect(JSON.parse representation).to match(
      "user" =>  Api::V1::UserRepresenter.new(user).as_json,
      "courses" => [], # not testing this since it's too expensive to generate meaningful course data
      "accounts_api_url" => OpenStax::Accounts.configuration.openstax_accounts_url + 'api',
      "accounts_profile_url" => OpenStax::Accounts.configuration.openstax_accounts_url + 'profile',
      "osweb_base_url" => 'https://cms.openstax.org',
      "tutor_api_url" => 'https://example.com/api',
      "response_validation" => {
        "url" => Rails.application.secrets['response_validation']['url'],
        "is_enabled" => Settings::ResponseValidation.is_enabled,
        "is_ui_enabled" => Settings::ResponseValidation.is_ui_enabled
      },
      "payments" => a_hash_including(
        "is_enabled" => Settings::Payments.payments_enabled,
        "js_url" => a_string_starting_with('http'),
        "base_url" => a_string_starting_with('http'),
        "product_uuid" => Rails.application.secrets['openstax']['payments']['product_uuid']
      ),
      "feature_flags" => a_hash_including(
        "is_payments_enabled" => Settings::Payments.payments_enabled
      ),
      "ui_settings" => {},
      "flash" => { "alert" => 'Nothing!' }
    )
  end

end
