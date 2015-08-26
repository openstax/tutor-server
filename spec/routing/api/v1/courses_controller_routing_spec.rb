require "rails_helper"

describe Api::V1::CoursesController, type: :routing, api: true, version: :v1 do

  describe "/api/courses/:course_id/dashboard" do
    it "routes to #dashboard" do
      expect(get '/api/courses/42/dashboard').to route_to('api/v1/courses#dashboard',
                                                          format: 'json', id: "42")
    end
  end

  describe "/api/courses/:course_id/plans" do
    it "routes to #plans" do
      expect(get '/api/courses/42/plans').to route_to('api/v1/courses#plans',
                                                      format: 'json', id: "42")
    end
  end

  describe "/api/courses/:course_id/tasks" do
    it "routes to #tasks" do
      expect(get '/api/courses/42/tasks').to route_to('api/v1/courses#tasks',
                                                      format: 'json', id: "42")
    end
  end

end
