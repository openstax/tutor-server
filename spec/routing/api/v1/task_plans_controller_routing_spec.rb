require "rails_helper"

RSpec.describe Api::V1::TaskPlansController, type: :routing, api: true, version: :v1 do

  context 'DELETE /api/task_plans/:id' do
    it "routes to #destroy" do
      expect(delete '/api/plans/42').to(
        route_to('api/v1/task_plans#destroy', format: 'json', id: '42')
      )
    end
  end

  context 'PUT /api/task_plans/:id/restore' do
    it "routes to #restore" do
      expect(put '/api/plans/42/restore').to(
        route_to('api/v1/task_plans#restore', format: 'json', id: '42')
      )
    end
  end

end
