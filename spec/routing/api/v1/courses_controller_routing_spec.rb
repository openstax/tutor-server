require 'rails_helper'

RSpec.describe Api::V1::CoursesController, type: :routing, api: true, version: :v1 do

  context 'GET /api/courses/:id/dashboard(/role/:role_id)' do
    context 'no role_id' do
      it 'routes to #dashboard' do
        expect(get '/api/courses/42/dashboard').to(
          route_to('api/v1/courses#dashboard', format: 'json', id: '42')
        )
      end
    end

    context 'role_id in path' do
      it 'routes to #dashboard' do
        expect(get '/api/courses/21/dashboard/role/42').to(
          route_to('api/v1/courses#dashboard', format: 'json', id: '21', role_id: '42')
        )
      end
    end

    context 'role_id in query params' do
      it 'routes to #dashboard' do
        expect(get '/api/courses/21/dashboard?role_id=42').to(
          route_to('api/v1/courses#dashboard', format: 'json', id: '21', role_id: '42')
        )
      end
    end
  end

  context 'GET /api/courses/:id/roster' do
    it 'routes to #roster' do
      expect(get '/api/courses/42/roster').to(
        route_to('api/v1/courses#roster', format: 'json', id: '42')
      )
    end
  end

  context '/api/courses/:id/clone' do
    it 'routes to #clone' do
      expect(post '/api/courses/42/clone').to(
        route_to('api/v1/courses#clone', format: 'json', id: '42')
      )
    end
  end

  context '/api/courses/dates' do
    it 'routes to #dates' do
      expect(post '/api/courses/dates').to route_to('api/v1/courses#dates', format: 'json')
    end
  end

end
