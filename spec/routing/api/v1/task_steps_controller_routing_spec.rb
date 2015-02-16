require "rails_helper"

describe Api::V1::TaskStepsController, :type => :routing, :api => true, :version => :v1 do

  describe "/api/tasks/:task_id/steps/:id" do
    it "routes to #show" do
      expect(get '/api/tasks/42/steps/23').to route_to('api/v1/task_steps#show', format: 'json', task_id: "42", id: "23")
    end

    it "routes to #completed" do
      expect(put '/api/tasks/42/steps/23/completed').to route_to('api/v1/task_steps#completed', format: 'json', task_id: "42", id: "23")
    end
  end

end
