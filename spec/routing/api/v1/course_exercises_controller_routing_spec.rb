require "rails_helper"

RSpec.describe Api::V1::CourseExercisesController, type: :routing, api: true, version: :v1 do
  context 'GET /api/courses/:course_id/exercises(/:pool_types)' do
    context 'no pool_types' do
      it 'routes to #show' do
        expect(get '/api/courses/42/exercises').to route_to(
          'api/v1/course_exercises#show', format: 'json', course_id: '42'
        )
      end
    end

    context 'pool_types in path' do
      it 'routes to #show' do
        expect(get '/api/courses/42/exercises/homework_core').to route_to(
          'api/v1/course_exercises#show',
          format: 'json', course_id: '42', pool_types: 'homework_core'
        )
      end
    end

    context 'pool_types in query params' do
      it 'routes to #show' do
        expect(get '/api/courses/42/exercises?pool_types=homework_core').to route_to(
          'api/v1/course_exercises#show',
          format: 'json', course_id: '42', pool_types: 'homework_core'
        )
      end
    end
  end
end
