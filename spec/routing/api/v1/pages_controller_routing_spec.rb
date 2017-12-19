require "rails_helper"

RSpec.describe Api::V1::PagesController, type: :routing, api: true, version: :v1 do

  context 'GET /api/pages/:uuid' do
    it "routes with a version" do
      expect(get: "/api/pages/1bb611e9-0ded-48d6-a107-fbb9bd900851@2").to route_to(
        format: "json",
        controller: "api/v1/pages",
        action: "get_page",
        uuid: "1bb611e9-0ded-48d6-a107-fbb9bd900851",
        version: "2"
      )
    end

    it "routes without a version" do
      expect(get: "/api/pages/1bb611e9-0ded-48d6-a107-fbb9bd900851").to route_to(
        format: "json",
        controller: "api/v1/pages",
        action: "get_page",
        uuid: "1bb611e9-0ded-48d6-a107-fbb9bd900851"
      )
    end
  end

end
