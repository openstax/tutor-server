require 'rails_helper'

RSpec.describe Api::V1::GuidesController, type: :routing, api: true, version: :v1 do
  context 'GET /api/courses/:course_id/guide(/role/:role_id)' do
    context 'no role_id' do
      it 'routes to #student' do
        expect(get '/api/courses/42/guide').to route_to(
          'api/v1/guides#student', format: 'json', course_id: '42'
        )
      end
    end

    context 'role_id in path' do
      it 'routes to #student' do
        expect(get '/api/courses/21/guide/role/42').to route_to(
          'api/v1/guides#student', format: 'json', course_id: '21', role_id: '42'
        )
      end
    end

    context 'role_id in query params' do
      it 'routes to #student' do
        expect(get '/api/courses/21/guide?role_id=42').to route_to(
          'api/v1/guides#student', format: 'json', course_id: '21', role_id: '42'
        )
      end
    end
  end

  context 'GET /api/courses/:course_id/teacher_guide(/role/:role_id)' do
    context 'no role_id' do
      it 'routes to #teacher' do
        expect(get '/api/courses/42/teacher_guide').to route_to(
          'api/v1/guides#teacher', format: 'json', course_id: '42'
        )
      end
    end

    context 'role_id in path' do
      it 'routes to #teacher' do
        expect(get '/api/courses/21/teacher_guide/role/42').to route_to(
          'api/v1/guides#teacher', format: 'json', course_id: '21', role_id: '42'
        )
      end
    end

    context 'role_id in query params' do
      it 'routes to #teacher' do
        expect(get '/api/courses/21/teacher_guide?role_id=42').to route_to(
          'api/v1/guides#teacher', format: 'json', course_id: '21', role_id: '42'
        )
      end
    end
  end
end
