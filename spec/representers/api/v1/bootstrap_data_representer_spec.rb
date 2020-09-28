require 'rails_helper'

RSpec.describe Api::V1::BootstrapDataRepresenter, type: :representer do
  let(:user)               { FactoryBot.create :user_profile }
  let(:period)             { FactoryBot.create :course_membership_period }
  let(:course)             { period.course }
  let!(:student_role)      { AddUserAsPeriodStudent[user: user, period: period] }
  let(:representation)     do
    described_class.new(user).to_json(
      user_options: {
        tutor_api_url: 'https://example.com/api',
        flash: { alert: 'Nothing!'},
        is_impersonating: false,
      }
    )
  end

  it "generates a JSON representation of data for a user to start work with" do
    secrets = Rails.application.secrets

    expect(JSON.parse(representation)).to match(
      {
        user:  Api::V1::UserRepresenter.new(user).as_json,
        courses: Api::V1::CoursesRepresenter.new(CollectCourseInfo[user: user]).as_json,
        accounts_api_url: OpenStax::Accounts.configuration.openstax_accounts_url + 'api',
        accounts_profile_url: OpenStax::Accounts.configuration.openstax_accounts_url + 'profile',
        assets_url: OpenStax::Utilities::Assets.url,
        osweb_base_url: 'https://cms.openstax.org',
        tutor_api_url: 'https://example.com/api',
        response_validation: {
          url: secrets.response_validation[:url],
          is_enabled: Settings::ResponseValidation.is_enabled,
          is_ui_enabled: Settings::ResponseValidation.is_ui_enabled
        },
        payments: {
          is_enabled: Settings::Payments.payments_enabled,
          js_url: a_string_starting_with('http'),
          base_url: a_string_starting_with('http'),
          product_uuid: secrets.openstax[:payments][:product_uuid]
        },
        feature_flags: {
          is_payments_enabled: Settings::Payments.payments_enabled,
          teacher_student_enabled: Settings::Db[:teacher_student_enabled],
          pulse_insights: Settings::Db[:pulse_insights],
          force_browser_reload: Settings::Db[:force_browser_reload]
        },
        ui_settings: {},
        is_impersonating: false,
        flash: { alert: 'Nothing!' }
      }.deep_stringify_keys
    )
  end
end
