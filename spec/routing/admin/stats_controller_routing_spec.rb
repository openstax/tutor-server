require "rails_helper"

RSpec.describe Admin::StatsController, type: :routing do

  describe "/admin/stats/courses" do
    it "routes to #courses" do
      expect(get '/admin/stats/courses').to route_to('admin/stats#courses')
    end
  end

  describe "/admin/stats/concept_coach" do
    it "routes to #concept_coach" do
      expect(get '/admin/stats/concept_coach').to route_to('admin/stats#concept_coach')
    end
  end

end
