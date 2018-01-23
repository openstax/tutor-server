require "rails_helper"

RSpec.describe 'Get authentication status', type: :request, version: :v1 do

  let(:application) { FactoryBot.create :doorkeeper_application }
  let(:user)        { FactoryBot.create(:user) }
  let(:anon_user)   { User::User.anonymous }

  context '#status' do
    it 'returns false for current_user when user is anonymous' do
      stub_current_user(anon_user)
      get('/auth/status')
      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash.stringify_keys.keys).not_to include('current_user')
    end

    it 'returns a token and current_user when user is logged in' do
      stub_current_user(user)
      expect{ get('/auth/status') }.to change { Doorkeeper::AccessToken.count }.by(1)
      expect(response).to have_http_status(:ok)
      token = Doorkeeper::AccessToken.find_by(resource_owner_id: user.id).token
      expect(response.body_as_hash).to match(
        access_token: token,
        errata_form_url: 'https://oscms.openstax.org/errata/form',
        tutor_api_url: a_string_starting_with('http'),
        hypothesis: a_hash_including(
          host: Rails.application.secrets['hypothesis']['host'],
          client_id: Rails.application.secrets['hypothesis']['client_id'],
          api_url: a_string_starting_with('http'),
          app_url: a_string_starting_with('http'),
          grant_token: kind_of(String),
          authority: Rails.application.secrets['hypothesis']['authority']
        ),
        feature_flags: a_hash_including(
          is_highlighting_allowed: false,
          is_payments_enabled: false
        ),
        payments: a_hash_including(
          is_enabled: Settings::Payments.payments_enabled,
          js_url: a_string_starting_with('http'),
          base_url: a_string_starting_with('http'),
          product_uuid: Rails.application.secrets['openstax']['payments']['product_uuid']
        ),
        accounts_api_url: a_string_starting_with('http'),
        accounts_profile_url: a_string_starting_with('http'),
        ui_settings: {},
        endpoints: {
          is_stubbed: true,
          logout: a_string_starting_with('http'),
          login: a_string_starting_with('http'),
          accounts_iframe: a_string_starting_with('http')
        },
        user: a_hash_including(
          name: user.name,
          is_admin: false,
          is_customer_service: false,
          is_content_analyst: false,
          is_test: true,
          faculty_status: 'no_faculty_info',
          viewed_tour_stats: [],
          self_reported_role: user.account.role,
          account_uuid: user.account.uuid,
          support_identifier: user.account.support_identifier,
          terms_signatures_needed: false,
          profile_url: a_string_starting_with('http')
        ),
        courses: []
      )
    end

    it 'sets cors headers' do
      get('/auth/status')
      expect(response.headers.keys).to include('Access-Control-Allow-Origin',
                                               'Access-Control-Allow-Methods',
                                               'Access-Control-Request-Method',
                                               'Access-Control-Allow-Headers',
                                               'Access-Control-Allow-Credentials')
    end

    it 'returns blank allow-origin if given one doesnt match' do
      get("/auth/status")
      expect(response).to have_http_status(:success)
      expect(response.headers['Access-Control-Allow-Origin']).to eq('')
    end

    it 'should reply to a CORS OPTIONS request' do
      origin = Rails.application.secrets.cc_origins.first + '/foo/bar'
      # It's difficult to test an OPTIONS request
      # reset and __send__ hacks from https://github.com/rspec/rspec-rails/issues/925
      reset!
      integration_session.__send__ :process, 'OPTIONS', '/auth/status', nil, \
        {'HTTP_ORIGIN' => origin, 'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'}
      expect(response.headers['Access-Control-Allow-Origin']).to eq(origin)
      expect(response.headers['Access-Control-Allow-Methods']).to eq 'GET, OPTIONS'
    end
  end

end
