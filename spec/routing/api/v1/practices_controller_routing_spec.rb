require "rails_helper"

RSpec.describe Api::V1::PracticesController, type: :routing, api: true, version: :v1 do

  context 'POST /api/courses/:id/practice' do
    it 'routes to #create' do
      expect(post '/api/courses/42/practice').to(
        route_to('api/v1/practices#create', format: 'json', id: '42')
      )
    end
  end

  context 'POST /api/courses/:id/practice/worst' do
    it 'routes to #create_worst' do
      expect(post '/api/courses/42/practice/worst').to(
        route_to('api/v1/practices#create_worst', format: 'json', id: '42')
      )
    end
  end

  context 'GET /api/courses/:id/practice' do
    it 'routes to #show' do
      expect(get '/api/courses/42/practice').to(
        route_to('api/v1/practices#show', format: 'json', id: '42')
      )
    end
  end

end
