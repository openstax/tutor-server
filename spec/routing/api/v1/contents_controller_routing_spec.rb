require "rails_helper"

describe Api::V1::ContentsController, type: :routing, api: true, version: :v1 do

  describe "/api/courses/:course_id/readings" do
    it "routes to #course_readings" do
      expect(get '/api/courses/42/readings').to route_to('api/v1/contents#course_readings',
                                                         format: 'json', id: "42")
    end
  end

  describe "/api/courses/:course_id/exercises" do
    it "routes to #course_exercises" do
      expect(get '/api/courses/42/exercises').to route_to('api/v1/contents#course_exercises',
                                                          format: 'json', id: "42")
    end
  end

  describe "/api/ecosystems/:ecosystem_id/readings" do
    it "routes to #ecosystem_readings" do
      expect(get '/api/ecosystems/42/readings').to route_to('api/v1/contents#ecosystem_readings',
                                                            format: 'json', id: "42")
    end
  end

  describe "/api/ecosystems/:ecosystem_id/exercises" do
    it "routes to #ecosystem_exercises" do
      expect(get '/api/ecosystems/42/exercises').to route_to('api/v1/contents#ecosystem_exercises',
                                                             format: 'json', id: "42")
    end
  end

end
