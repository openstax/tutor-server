require "rails_helper"

RSpec.describe Api::V1::PracticesController, type: :routing, api: true, version: :v1 do
  context 'POST /api/courses/:course_id/practice(/role/:role_id)' do
    context 'no role_id' do
      it 'routes to #create' do
        expect(post '/api/courses/42/practice').to route_to(
          'api/v1/practices#create', format: 'json', course_id: '42'
        )
      end
    end

    context 'role_id in path' do
      it 'routes to #create' do
        expect(post '/api/courses/21/practice/role/42').to route_to(
          'api/v1/practices#create', format: 'json', course_id: '21', role_id: '42'
        )
      end
    end

    context 'role_id in query params' do
      it 'routes to #create' do
        expect(post '/api/courses/21/practice?role_id=42').to route_to(
          'api/v1/practices#create', format: 'json', course_id: '21', role_id: '42'
        )
      end
    end
  end

  context 'POST /api/courses/:course_id/practice/worst(/role/:role_id)' do
    context 'no role_id' do
      it 'routes to #create_worst' do
        expect(post '/api/courses/42/practice/worst').to route_to(
          'api/v1/practices#create_worst', format: 'json', course_id: '42'
        )
      end
    end

    context 'role_id in path' do
      it 'routes to #create_worst' do
        expect(post '/api/courses/21/practice/worst/role/42').to route_to(
          'api/v1/practices#create_worst', format: 'json', course_id: '21', role_id: '42'
        )
      end
    end

    context 'role_id in query params' do
      it 'routes to #create_worst' do
        expect(post '/api/courses/21/practice/worst?role_id=42').to route_to(
          'api/v1/practices#create_worst', format: 'json', course_id: '21', role_id: '42'
        )
      end
    end
  end
end
