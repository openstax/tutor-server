require "rails_helper"

RSpec.describe Api::V1::TaskStepsController, type: :routing, api: true, version: :v1 do

  context "GET /api/tasks/:task_id/steps/:id" do
    it "routes to #show" do
      expect(get '/api/steps/23').to route_to('api/v1/task_steps#show', format: 'json', id: "23")
    end
  end

  context "PUT /api/tasks/:task_id/steps/:id" do
    it "routes to #update" do
      expect(put '/api/steps/23').to(
        route_to('api/v1/task_steps#update', format: 'json', id: "23")
      )
    end
  end

end
