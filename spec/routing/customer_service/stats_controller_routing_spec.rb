require "rails_helper"

RSpec.describe CustomerService::StatsController, type: :routing do

  describe "/customer_service/stats/courses" do
    it "routes to #courses" do
      expect(get '/customer_service/stats/courses').to(
        route_to('customer_service/stats#courses')
      )
    end
  end

end
