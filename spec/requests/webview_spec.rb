require "rails_helper"

RSpec.describe "Webview", type: :request do
  let(:chrome_ua) {
    { 'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_4; en-US) AppleWebKit/533.4 (KHTML, like Gecko) Chrome/5.0.375.99 Safari/533.4' }
  }

  describe 'GET /courses/enroll/blah' do

    it 'renders welcome screen' do
      get '/enroll/whatever', {}, chrome_ua
      expect(response).to render_template(:enroll)
    end

    it 'start does not direct accounts to use the alternate signup' do
      get '/enroll/start/whatever', {}, chrome_ua
      expect(redirect_query_hash).not_to have_key(:signup_at)
    end

    it 'directs accounts to go straight to signup for student' do
      get '/enroll/start/whatever', {}, chrome_ua
      expect(redirect_query_hash[:go]).to eq 'student_signup'
    end
  end

  describe "supported browser check" do
    let(:user)        { FactoryGirl.create(:user) }

    # list of browser UA
    # https://github.com/fnando/browser/blob/master/test/ua.yml
    [
      ['IE 9', 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)'],
      ['IE 10', 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0; EIE10;ENUSMSN)'],
      ['IE 11', 'Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko'],
      ['IE Mobile', 'Mozilla/4.0 (compatible; MSIE 6.0; Windows CE; IEMobile 6.12)'],
      ['Blackberry', 'BlackBerry8100/4.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1 VendorID/103'],
      ['Safari 9', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9'],

    ].each do |name, ua|
      it "#{name} is not supported" do
        stub_current_user(user)
        get dashboard_url, {}, { 'HTTP_USER_AGENT' => ua }
        expect(response).to redirect_to(browser_upgrade_path(go: dashboard_url))
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
        stub_current_user(user)
        get '/', {}, { 'HTTP_USER_AGENT' => ua }
        expect(response).to redirect_to(dashboard_path)
      end
    end

  end

end
