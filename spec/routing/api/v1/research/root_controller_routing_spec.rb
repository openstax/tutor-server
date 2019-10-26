require 'rails_helper'

RSpec.describe Api::V1::Research::RootController, type: :routing, api: true, version: :v1 do
  context 'POST /api/research' do
    it 'routes to #research' do
      expect(post '/api/research').to route_to 'api/v1/research/root#research', format: 'json'
    end
  end
end
