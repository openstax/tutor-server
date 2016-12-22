require "rails_helper"

RSpec.describe "Webview", type: :request do

  describe 'GET /courses/enroll/blah' do
    it 'does not direct accounts to use the alternate signup' do
      get '/enroll/whatever'
      expect(redirect_query_hash).not_to have_key(:signup_at)
    end
  end

end

