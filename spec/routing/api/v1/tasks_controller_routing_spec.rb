require "rails_helper"

RSpec.describe Api::V1::TasksController, type: :routing, api: true, version: :v1 do

  context 'DELETE /api/tasks/:id' do
    it "routes to #destroy" do
      expect(delete '/api/tasks/42').to route_to('api/v1/tasks#destroy', format: 'json', id: '42')
    end
  end

end
