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
      "errata_form_url" => 'https://oscms.openstax.org/errata/form',
      "tutor_api_url" => 'https://example.com/api',
      "payments" => a_hash_including(
        "is_enabled" => Settings::Payments.payments_enabled,
        "js_url" => a_string_starting_with('http'),
        "base_url" => a_string_starting_with('http'),
        "product_uuid" => Rails.application.secrets['openstax']['payments']['product_uuid']
      ),
      "ui_settings" => {},
      "flash" => { "alert" => 'Nothing!' }
    )
  end

end
