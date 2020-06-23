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
end
