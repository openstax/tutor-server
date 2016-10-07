require "rails_helper"

RSpec.describe Api::V1::PeriodsController, type: :routing, api: true, version: :v1 do

  context 'DELETE /api/periods/:id' do
    it 'routes to #destroy' do
      expect(delete '/api/periods/42').to(
        route_to('api/v1/periods#destroy', format: 'json', id: '42')
      )
    end
  end

  context 'PUT /api/periods/:id/restore' do
    it 'routes to #restore' do
      expect(put '/api/periods/42/restore').to(
        route_to('api/v1/periods#restore', format: 'json', id: '42')
      )
    end
  end

end
