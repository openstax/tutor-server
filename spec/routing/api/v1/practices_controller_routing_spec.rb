require "rails_helper"

RSpec.describe Api::V1::PracticesController, type: :routing, api: true, version: :v1 do

  context 'POST /api/courses/:id/practice/(role/:role_id)' do
    it 'routes to #create_specific with a role_id' do
      expect(post '/api/courses/42/practice/role/84').to(
        route_to('api/v1/practices#create_specific', format: 'json', id: '42', role_id: '84')
      )
    end

    it 'routes to #create_specific without a role_id' do
      expect(post '/api/courses/42/practice').to(
        route_to('api/v1/practices#create_specific', format: 'json', id: '42')
      )
    end
  end

  context 'POST /api/courses/:id/practice/worst/(role/:role_id)' do
    it 'routes to #create_worst with a role_id' do
      expect(post '/api/courses/42/practice/worst/role/84').to(
        route_to('api/v1/practices#create_worst', format: 'json', id: '42', role_id: '84')
      )
    end

    it 'routes to #create_worst without a role_id' do
      expect(post '/api/courses/42/practice/worst').to(
        route_to('api/v1/practices#create_worst', format: 'json', id: '42')
      )
    end
  end

  context 'GET /api/courses/:id/practice/(role/:role_id)' do
    it 'routes to #show with a role_id' do
      expect(get '/api/courses/42/practice/role/84').to(
        route_to('api/v1/practices#show', format: 'json', id: '42', role_id: '84')
      )
    end

    it 'routes to #show without a role_id' do
      expect(get '/api/courses/42/practice').to(
        route_to('api/v1/practices#show', format: 'json', id: '42')
      )
    end
  end

end
