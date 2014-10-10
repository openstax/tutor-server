require "rails_helper"

module Api::V1
  RSpec.describe UsersController, :type => :routing, api: true, version: :v1 do
    describe "routing" do

      it "routes to #index" do
        expect(get("/api/users")).to route_to("api/v1/users#index", format: "json")
      end

      it "routes to #show" do
        expect(get("/api/user")).to route_to("api/v1/users#show", format: "json")
      end

      it "routes to #update" do
        expect(put("/api/user")).to route_to("api/v1/users#update", format: "json")
      end

      it "routes to #destroy" do
        expect(delete("/api/user")).to route_to("api/v1/users#destroy", format: "json")
      end

    end
  end
end
