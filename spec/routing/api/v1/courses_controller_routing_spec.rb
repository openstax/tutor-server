require "rails_helper"

describe Api::V1::CoursesController, :type => :routing, :api => true, :version => :v1 do

  describe "/api/courses/:course_id/readings" do
    it "routes to #readings" do
      expect(get '/api/courses/42/readings').to route_to('api/v1/courses#readings', format: 'json', id: "42")
    end
  end

end
