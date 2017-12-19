require "rails_helper"

RSpec.describe Api::V1::EcosystemsController, type: :routing, api: true, version: :v1 do

  context "GET /api/ecosystems/:ecosystem_id/readings" do
    it "routes to #readings" do
      expect(get '/api/ecosystems/42/readings').to route_to('api/v1/ecosystems#readings',
                                                            format: 'json', id: "42")
    end
  end

  context "GET /api/ecosystems/:ecosystem_id/exercises(/:pool_types)" do
    it "routes to #exercises when the pool_types are not given" do
      expect(get '/api/ecosystems/42/exercises').to route_to('api/v1/ecosystems#exercises',
                                                             format: 'json', id: "42")
    end

    it "routes to #exercises when the pool_types are given" do
      expect(get '/api/ecosystems/42/exercises/homework_core').to(
        route_to('api/v1/ecosystems#exercises', format: 'json', id: '42',
                                                pool_types: 'homework_core')
      )
    end
  end

end
