require 'rails_helper'

RSpec.describe WebviewController, type: :controller do
  let!(:chrome_ua) {
    { 'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_4; en-US) AppleWebKit/533.4 (KHTML, like Gecko) Chrome/5.0.375.99 Safari/533.4' }
  }
  let!(:contract)       { FinePrint::Contract.create!(name: 'general_terms_of_use',
                                                      title: 'General Terms of Use',
                                                      content: Faker::Lorem.paragraphs,
                                                      version: 10) }
  let(:new_user)        { FactoryGirl.create(:user, skip_terms_agreement: true) }
  let(:registered_user) { FactoryGirl.create(:user) }

  before(:each) { request.headers.merge! chrome_ua }

  describe 'GET home' do
    it 'renders a static page for anonymous' do
      get :home, headers: chrome_ua
      expect(response).to have_http_status(:success)
    end

    it 'redirects logged in users to the dashboard' do
      controller.sign_in new_user
      get :home
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirect to CC landing page when param set' do
      get :home, cc: "1"
      expect(response).to redirect_to('http://cc.openstax.org')
    end

  end

  describe "supported browser check" do
    # list of browser UA
    # https://github.com/fnando/browser/blob/master/test/ua.yml
    [
      ['IE 9', 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)'],
      ['IE 10', 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0; EIE10;ENUSMSN)'],
      ['IE Mobile', 'Mozilla/4.0 (compatible; MSIE 6.0; Windows CE; IEMobile 6.12)'],
      ['Blackberry', 'BlackBerry8100/4.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1 VendorID/103'],
      ['Safari 9', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9'],

    ].each do |name, ua|
      it "#{name} is not supported" do
        request.headers['HTTP_USER_AGENT'] = ua
        controller.sign_in new_user
        get :home
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(browser_upgrade_path)
      end
    end

    [
      ['MS Edge', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36 Edge/12.0'],
      ['Firefox', 'Mozilla/5.0 (X11; Ubuntu; Linux armv7l; rv:17.0) Gecko/20100101 Firefox/17.0'],
      ['Chrome', 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_4; en-US) AppleWebKit/533.4 (KHTML, like Gecko) Chrome/5.0.375.99 Safari/533.4'],
      ['Safari 10', 'Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_1 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Mobile/14A403 Safari/602.1'],
      ['Safari 11', 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Safari/604.1.38']
    ].each do |name, ua|
      it "#{name} is supported" do
        request.headers['HTTP_USER_AGENT'] = ua
        controller.sign_in new_user
        get :home
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(dashboard_path)
      end
    end

  end

  describe 'GET *anything' do
    it 'requires a user' do
      get :index
      expect(response).to redirect_to(controller.send(:openstax_accounts_login_path))
    end

    it 'requires agreement to contracts' do
      controller.sign_in new_user
      get :index
      expect(response).to have_http_status(:ok)
    end

    context "as a signed in user" do
      render_views

      it 'sets boostrap data in script tag' do
        controller.sign_in registered_user
        fake_flash(:alert, "Alarm!")

        get :index
        expect(response).to have_http_status(:success)
        doc = Nokogiri::HTML(response.body)
        data = ::JSON.parse(doc.css('body script#tutor-boostrap-data').inner_text)
        expect(data).to include({
          'courses'=> CollectCourseInfo[user: registered_user].as_json,
          'user' => Api::V1::UserRepresenter.new(registered_user).as_json,
          'flash' => {alert: "Alarm!"}.as_json
        })
      end
    end

  end


end
