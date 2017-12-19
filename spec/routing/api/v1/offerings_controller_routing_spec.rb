require 'rails_helper'

RSpec.describe Api::V1::OfferingsController, type: :routing, api: true, version: :v1 do

  context 'GET /api/offerings' do
    it 'routes to #index' do
      expect(get '/api/offerings').to route_to('api/v1/offerings#index', format: 'json')
    end
  end

end
