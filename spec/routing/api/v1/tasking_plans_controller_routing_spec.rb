require 'rails_helper'

RSpec.describe Api::V1::TaskingPlansController, type: :routing, api: true, version: :v1 do
  context 'PUT /api/tasking_plans/:id/grade' do
    it 'routes to #grade' do
      expect(put '/api/tasking_plans/42/grade').to(
        route_to('api/v1/tasking_plans#grade', format: 'json', id: '42')
      )
    end
  end
end
