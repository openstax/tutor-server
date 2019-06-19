require "rails_helper"

RSpec.describe Api::V1::PerformanceReportsController, type: :routing, api: true, version: :v1 do
  context 'GET /api/courses/:course_id/performance(/role/:role_id)' do
    context 'no role_id' do
      it 'routes to #index' do
        expect(get '/api/courses/42/performance').to route_to(
          'api/v1/performance_reports#index', format: 'json', course_id: '42'
        )
      end
    end

    context 'role_id in path' do
      it 'routes to #index' do
        expect(get '/api/courses/21/performance/role/42').to route_to(
          'api/v1/performance_reports#index', format: 'json', course_id: '21', role_id: '42'
        )
      end
    end

    context 'role_id in query params' do
      it 'routes to #index' do
        expect(get '/api/courses/21/performance?role_id=42').to route_to(
          'api/v1/performance_reports#index', format: 'json', course_id: '21', role_id: '42'
        )
      end
    end
  end

  context 'POST /api/courses/:course_id/performance/export(/role/:role_id)' do
    context 'no role_id' do
      it 'routes to #export' do
        expect(post '/api/courses/42/performance/export').to route_to(
          'api/v1/performance_reports#export', format: 'json', course_id: '42'
        )
      end
    end

    context 'role_id in path' do
      it 'routes to #export' do
        expect(post '/api/courses/21/performance/export/role/42').to route_to(
          'api/v1/performance_reports#export', format: 'json', course_id: '21', role_id: '42'
        )
      end
    end

    context 'role_id in query params' do
      it 'routes to #export' do
        expect(post '/api/courses/21/performance/export?role_id=42').to route_to(
          'api/v1/performance_reports#export', format: 'json', course_id: '21', role_id: '42'
        )
      end
    end
  end

  context 'GET /api/courses/:course_id/performance/exports(/role/:role_id)' do
    context 'no role_id' do
      it 'routes to #index' do
        expect(get '/api/courses/42/performance/exports').to route_to(
          'api/v1/performance_reports#exports', format: 'json', course_id: '42'
        )
      end
    end

    context 'role_id in path' do
      it 'routes to #index' do
        expect(get '/api/courses/21/performance/exports/role/42').to route_to(
          'api/v1/performance_reports#exports', format: 'json', course_id: '21', role_id: '42'
        )
      end
    end

    context 'role_id in query params' do
      it 'routes to #index' do
        expect(get '/api/courses/21/performance/exports?role_id=42').to route_to(
          'api/v1/performance_reports#exports', format: 'json', course_id: '21', role_id: '42'
        )
      end
    end
  end
end
