require 'rails_helper'

describe Api::V1::CoursesController, type: :routing, api: true, version: :v1 do

  context 'GET /api/courses/:course_id/dashboard' do
    it 'routes to #dashboard' do
      expect(get '/api/courses/42/dashboard').to(
        route_to('api/v1/courses#dashboard', format: 'json', id: '42')
      )
    end
  end

  context 'GET /api/courses/:course_id/cc/dashboard' do
    it 'routes to #cc_dashboard' do
      expect(get '/api/courses/42/cc/dashboard').to(
        route_to('api/v1/courses#cc_dashboard', format: 'json', id: '42')
      )
    end
  end

  context 'GET /api/courses/:course_id/roster' do
    it 'routes to #roster' do
      expect(get '/api/courses/42/roster').to(
        route_to('api/v1/courses#roster', format: 'json', id: '42')
      )
    end
  end

  context '/api/courses/:course_id/clone' do
    it 'routes to #clone' do
      expect(get '/api/courses/42/clone').to(
        route_to('api/v1/courses#clone', format: 'json', id: '42')
      )
    end
  end

end
