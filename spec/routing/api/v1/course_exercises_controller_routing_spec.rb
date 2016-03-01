require "rails_helper"

describe Api::V1::CourseExercisesController, type: :routing, api: true, version: :v1 do

  describe "GET /api/courses/:course_id/exercises" do
    it "routes to #index" do
      expect(get '/api/courses/42/exercises').to route_to('api/v1/course_exercises#index',
                                                          format: 'json', course_id: '42')
    end
  end

  describe "PATCH /api/courses/:course_id/exercises/:exercise_id" do
    it "routes to #update" do
      expect(patch '/api/courses/42/exercises/21').to route_to('api/v1/course_exercises#update',
                                                               format: 'json',
                                                               course_id: '42',
                                                               id: '21')
    end
  end

end
