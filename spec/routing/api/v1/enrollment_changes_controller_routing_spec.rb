require 'rails_helper'

RSpec.describe Api::V1::EnrollmentChangesController, type: :routing, api: true, version: :v1 do

  context '/api/enrollment_changes' do
    it 'routes to #create' do
      expect(post '/api/enrollment_changes').to route_to('api/v1/enrollment_changes#create',
                                                         format: 'json')
    end
  end

  context '/api/enrollment_changes/:enrollment_change_id/approve' do
    it 'routes to #approve' do
      expect(put '/api/enrollment_changes/42/approve').to(
        route_to('api/v1/enrollment_changes#approve', format: 'json', id: '42')
      )
    end
  end

end
