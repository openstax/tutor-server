require "rails_helper"

RSpec.describe Admin::StatsController, type: :routing do

  describe "/admin/stats/courses" do
    it "routes to #courses" do
      expect(get '/admin/stats/courses').to route_to('admin/stats#courses')
    end
  end

end
