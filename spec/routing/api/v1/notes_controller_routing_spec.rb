require "rails_helper"

RSpec.describe Api::V1::NotesController, type: :routing, api: true, version: :v1 do
  context 'GET /api/courses/:course_id/notes/:chapter.:section' do
    it 'routes to #index' do
      expect(get '/api/courses/21/notes/4.2').to route_to(
        'api/v1/notes#index', format: 'json', course_id: '21', chapter: '4', section: '2'
      )
    end
  end

  context 'POST /api/courses/:course_id/notes/:chapter.:section(/role/:role_id)' do
    context 'no role_id' do
      it 'routes to #create' do
        expect(post '/api/courses/21/notes/4.2').to route_to(
          'api/v1/notes#create', format: 'json', course_id: '21', chapter: '4', section: '2'
        )
      end
    end

    context 'role_id in path' do
      it 'routes to #create' do
        expect(post '/api/courses/21/notes/4.2/role/84').to route_to(
          'api/v1/notes#create',
          format: 'json', course_id: '21', chapter: '4', section: '2', role_id: '84'
        )
      end
    end

    context 'role_id in query params' do
      it 'routes to #create' do
        expect(post '/api/courses/21/notes/4.2?role_id=84').to route_to(
          'api/v1/notes#create',
          format: 'json', course_id: '21', chapter: '4', section: '2', role_id: '84'
        )
      end
    end
  end

  context 'PATCH /api/courses/:course_id/notes/:chapter.:section/:id' do
    it 'routes to #update' do
      expect(patch '/api/courses/21/notes/4.2/84').to route_to(
        'api/v1/notes#update',
        format: 'json', course_id: '21', chapter: '4', section: '2', id: '84'
      )
    end
  end

  context 'DELETE /api/courses/:course_id/notes/:chapter.:section/:id' do
    it 'routes to #destroy' do
      expect(delete '/api/courses/21/notes/4.2/84').to route_to(
        'api/v1/notes#destroy',
        format: 'json', course_id: '21', chapter: '4', section: '2', id: '84'
      )
    end
  end

  context 'GET /api/courses/:course_id/highlighted_sections' do
    it 'routes to #highlighted_sections' do
      expect(get '/api/courses/42/highlighted_sections').to route_to(
        'api/v1/notes#highlighted_sections', format: 'json', course_id: '42'
      )
    end
  end
end
