require 'rails_helper'

RSpec.describe Api::V1::RolesController, type: :routing, api: true, version: :v1 do

  context 'PUT /api/roles/:id/become' do
    it 'routes to #become' do
      expect(put '/api/roles/42/become').to(
        route_to('api/v1/roles#become', format: 'json', id: '42')
      )
    end
  end

end
