require 'rails_helper'

RSpec.describe StaticPagesController, type: :request do
  context 'GET copyright' do
    it 'returns http success' do
      get copyright_url
      expect(response).to have_http_status(:success)
    end
  end

  context 'GET omniauth_failure' do
    it 'sets flash and redirects to root' do
      get auth_failure_url, params: { message: 'blah' }
      expect(flash[:error]).to include 'blah'
      expect(response).to redirect_to(root_url)
    end
  end
end
