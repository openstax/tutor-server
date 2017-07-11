require "rails_helper"

RSpec.describe "Webview", type: :request do

  describe 'GET /courses/enroll/blah' do

    it 'renders welcome screen' do
      get '/enroll/whatever'
      expect(response).to render_template(:enroll)
    end

    it 'start does not direct accounts to use the alternate signup' do
      get '/enroll/start/whatever'
      expect(redirect_query_hash).not_to have_key(:signup_at)
    end

    it 'directs accounts to go straight to signup for student' do
      get '/enroll/start/whatever'
      expect(redirect_query_hash[:go]).to eq 'student_signup'
    end
  end

end
