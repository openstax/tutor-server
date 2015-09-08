require "rails_helper"

describe Api::V1::EcosystemsController, type: :routing, api: true, version: :v1 do

  describe "/api/ecosystems/:ecosystem_id/readings" do
    it "routes to #readings" do
      expect(get '/api/ecosystems/42/readings').to route_to('api/v1/ecosystems#readings',
                                                            format: 'json', id: "42")
    end
  end

  describe "/api/ecosystems/:ecosystem_id/exercises" do
    it "routes to #exercises" do
      expect(get '/api/ecosystems/42/exercises').to route_to('api/v1/ecosystems#exercises',
                                                             format: 'json', id: "42")
    end
  end

end
