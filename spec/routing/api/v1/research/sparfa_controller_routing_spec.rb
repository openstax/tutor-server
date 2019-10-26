require 'rails_helper'

RSpec.describe Api::V1::Research::SparfaController, type: :routing, api: true, version: :v1 do
  context 'POST /api/research/sparfa/students' do
    it 'routes to #students' do
      expect(post '/api/research/sparfa/students').to(
        route_to 'api/v1/research/sparfa#students', format: 'json'
      )
    end
  end

  context 'POST /api/research/sparfa/task_plans' do
    it 'routes to #task_plans' do
      expect(post '/api/research/sparfa/task_plans').to(
        route_to 'api/v1/research/sparfa#task_plans', format: 'json'
      )
    end
  end
end
