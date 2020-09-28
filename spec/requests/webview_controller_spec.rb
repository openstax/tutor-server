require 'rails_helper'

RSpec.describe WebviewController, type: :request do

  let!(:contract)       do
    FinePrint::Contract.create!(name: 'general_terms_of_use',
                                title: 'General Terms of Use',
                                content: Faker::Lorem.paragraphs,
                                version: 10)
  end
  let(:new_user)        { FactoryBot.create(:user_profile, skip_terms_agreement: true) }
  let(:registered_user) { FactoryBot.create(:user_profile) }

  let(:headers)         { { 'User-Agent': chrome_ua } }

  context 'GET home' do
    it 'renders a static page for anonymous' do
      get root_url, headers: headers
      expect(response).to have_http_status(:success)
    end

    it 'redirects logged in users to the dashboard' do
      sign_in! new_user
      get root_url, headers: headers
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(dashboard_url)
    end

    it 'redirects unsupported browsers to message' do
      get root_url, headers: { 'User-Agent': unsupported_ua }
      expect(response).to redirect_to(browser_upgrade_url(go: root_url))
    end
  end

  context 'GET *anything' do
    it 'requires a user' do
      get "/#{SecureRandom.hex}", headers: headers
      expect(response).to redirect_to(controller.send(:openstax_accounts_login_path))
    end

    it 'requires agreement to contracts' do
      sign_in! new_user
      get "/#{SecureRandom.hex}", headers: headers
      expect(response).to have_http_status(:ok)
    end

    context 'as a signed in user' do
      before { sign_in! registered_user }

      it 'sets boostrap data in script tag' do
        get "/#{SecureRandom.hex}", headers: headers
        expect(response).to have_http_status(:success)
        doc = Nokogiri::HTML(response.body)
        data = ::JSON.parse(doc.css('body script#tutor-boostrap-data').inner_text)
        expect(data).to include(
          'courses'=> CollectCourseInfo[user: registered_user].as_json,
          'user' => Api::V1::UserRepresenter.new(registered_user).as_json
        )
      end

      it 'has url to tutor js asset' do
        get "/#{SecureRandom.hex}", headers: headers
        expect(response.body).to include "src='#{OpenStax::Utilities::Assets.url_for('tutor.js')}'"
      end
    end
  end

  context 'GET /courses/enroll/blah' do
    it 'renders welcome screen' do
      get token_enroll_url('whatever'), headers: headers
      expect(response).to render_template(:enroll)
    end

    it 'start does not direct accounts to use the alternate signup' do
      get start_enrollment_url('whatever'), headers: headers
      expect(redirect_query_hash).not_to have_key(:signup_at)
    end

    it 'directs accounts to go straight to signup for student' do
      get start_enrollment_url('whatever'), headers: headers
      expect(redirect_query_hash[:go]).to eq 'student_signup'
    end
  end

  context 'supported browser check' do
    let(:user) { FactoryBot.create(:user_profile) }

    before { sign_in! user }

    # list of browser UA
    # https://github.com/fnando/browser/blob/master/test/ua.yml
    [
      ['IE 9', 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)'],
      ['IE 10', 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0; EIE10;ENUSMSN)'],
      ['IE 11', 'Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko'],
      ['IE Mobile', 'Mozilla/4.0 (compatible; MSIE 6.0; Windows CE; IEMobile 6.12)'],
      ['Blackberry', 'BlackBerry8100/4.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1 VendorID/103'],
      ['Safari 8', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_90) AppleWebKit/600.1.25 (KHTML, like Gecko) Version/8.0 Safari/600.1.25']
    ].each do |name, ua|
      it "#{name} is not supported" do
        get dashboard_url, headers: { 'User-Agent': ua }
        expect(response).to redirect_to(browser_upgrade_url(go: dashboard_url))
      end
    end

    [
      ['MS Edge', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36 Edge/12.0'],
      ['Firefox', 'Mozilla/5.0 (X11; Ubuntu; Linux armv7l; rv:17.0) Gecko/20100101 Firefox/17.0'],
      ['Chrome', 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_4; en-US) AppleWebKit/533.4 (KHTML, like Gecko) Chrome/5.0.375.99 Safari/533.4'],
      ['Safari 10', 'Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_1 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Mobile/14A403 Safari/602.1'],
      ['Safari 11', 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Safari/604.1.38'],
      ['Safari 9', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9'],
      ['Newish Android', 'Mozilla/5.0 (Linux; Android 5.0; Nexus 5 Build/LPX13D) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.102 Mobile Safari/537.36']
    ].each do |name, ua|
      it "#{name} is supported" do
        get dashboard_url, headers: { 'User-Agent': ua }
        expect(response).to be_ok
      end
    end
  end

  context 'non_student_signup' do
    def redirect_uri
      expect(response.code).to match '302|301'
      uri = URI.parse(response.headers['Location'])
    end

    def redirect_path
      redirect_uri.path
    end

    def redirect_query_hash
      Rack::Utils.parse_nested_query(redirect_uri.query).symbolize_keys
    end

    it 'lets teachers signup' do
      get non_student_signup_url

      expect(redirect_path).to eq dashboard_path
      expect(redirect_query_hash).to include(block_sign_up: 'false', straight_to_sign_up: 'true')

      follow_redirect!

      expect(redirect_path).to eq openstax_accounts.login_path
      expect(redirect_query_hash).to include(go: 'signup')
    end
  end
end
