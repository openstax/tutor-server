require "rails_helper"

RSpec.describe Api::V1::CourseExercisesController, type: :routing, api: true, version: :v1 do

  describe "/api/courses/:course_id/exercises(/:pool_types)" do
    it "routes to #show when the pool_types are not given" do
      expect(get '/api/courses/42/exercises').to route_to('api/v1/course_exercises#show',
                                                          format: 'json', course_id: "42")
    end

    it "routes to #show when the pool_types are given" do
      expect(get '/api/courses/42/exercises/homework_core').to(
        route_to('api/v1/course_exercises#show', format: 'json', course_id: '42',
                                                 pool_types: 'homework_core')
      )
    end
  end

  describe "PATCH /api/courses/:course_id/exercises" do
    it "routes to #update" do
      expect(patch '/api/courses/42/exercises').to route_to('api/v1/course_exercises#update',
                                                            format: 'json', course_id: '42')
    end
  end

end
