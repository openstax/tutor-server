require 'rails_helper'

RSpec.describe Api::V1::EnrollmentController, type: :routing, api: true, version: :v1 do

  context 'POST /api/enrollment' do
    it 'routes to #create' do
      expect(post '/api/enrollment').to route_to('api/v1/enrollment#create', format: 'json')
    end
  end

  context 'GET /api/enrollment/:course_uuid/choices' do
    it 'routes to #choices' do
      uuid = 'cc3c6ff9-83d8-4375-94be-8c7ae3024938'
      expect(get "/api/enrollment/#{uuid}/choices").to(
        route_to('api/v1/enrollment#choices', format: 'json', id: uuid)
      )
    end
  end

  context 'PUT /api/enrollment/:enrollment_change_id/approve' do
    it 'routes to #approve' do
      expect(put '/api/enrollment/42/approve').to(
        route_to('api/v1/enrollment#approve', format: 'json', id: '42')
      )
    end
  end

end
