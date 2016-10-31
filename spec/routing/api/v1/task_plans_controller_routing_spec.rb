require 'rails_helper'

RSpec.describe Api::V1::TaskPlansController, type: :routing, api: true, version: :v1 do

  context 'GET /api/courses/:course_id/plans' do
    it "routes to #index" do
      expect(get '/api/courses/42/plans').to(
        route_to('api/v1/task_plans#index', format: 'json', course_id: '42')
      )
    end
  end

  context 'POST /api/courses/:course_id/plans' do
    it "routes to #create" do
      expect(post '/api/courses/42/plans').to(
        route_to('api/v1/task_plans#create', format: 'json', course_id: '42')
      )
    end
  end

  context 'GET /api/plans/:id' do
    it "routes to #read" do
      expect(get '/api/plans/42').to route_to('api/v1/task_plans#show', format: 'json', id: '42')
    end
  end

  [:put, :patch].each do |method|
    context "#{method.capitalize} /api/plans/:id" do
      it "routes to #update" do
        expect(send(method, '/api/plans/42')).to(
          route_to('api/v1/task_plans#update', format: 'json', id: '42')
        )
      end
    end
  end

  context 'DELETE /api/plans/:id' do
    it "routes to #destroy" do
      expect(delete '/api/plans/42').to(
        route_to('api/v1/task_plans#destroy', format: 'json', id: '42')
      )
    end
  end

  context 'PUT /api/plans/:id/restore' do
    it "routes to #restore" do
      expect(put '/api/plans/42/restore').to(
        route_to('api/v1/task_plans#restore', format: 'json', id: '42')
      )
    end
  end

end
