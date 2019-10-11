require "rails_helper"

RSpec.describe Api::V1::NotesController, type: :routing, api: true, version: :v1 do
  context 'GET /api/pages/:page_id/notes' do
    it 'routes to #index' do
      expect(get '/api/pages/b2f8c9a0-46f1-4a45-822f-e7c4a5d22849/notes').to route_to(
        'api/v1/notes#index', format: 'json', page_id: 'b2f8c9a0-46f1-4a45-822f-e7c4a5d22849'
      )
    end
  end

  context 'POST /api/pages/:page_id/notes' do
    it 'routes to #create' do
      expect(post '/api/pages/b2f8c9a0-46f1-4a45-822f-e7c4a5d22849/notes').to route_to(
        'api/v1/notes#create', format: 'json', page_id: 'b2f8c9a0-46f1-4a45-822f-e7c4a5d22849'
      )
    end
  end

  context 'PATCH /api/notes/:id' do
    it 'routes to #update' do
      expect(patch '/api/notes/42').to route_to 'api/v1/notes#update', format: 'json', id: '42'
    end
  end

  context 'PUT /api/notes/:id' do
    it 'routes to #update' do
      expect(put '/api/notes/42').to route_to 'api/v1/notes#update', format: 'json', id: '42'
    end
  end

  context 'DELETE /api/notes/:id' do
    it 'routes to #destroy' do
      expect(delete '/api/notes/42').to route_to 'api/v1/notes#destroy', format: 'json', id: '42'
    end
  end

  context 'GET /api/books/:book_uuid/highlighted_sections' do
    it 'routes to #highlighted_sections' do
      expect(get '/api/books/b9fdc912-6ea6-451a-912c-b52ea6238bb2/highlighted_sections').to(
        route_to 'api/v1/notes#highlighted_sections',
                 format: 'json', book_uuid: 'b9fdc912-6ea6-451a-912c-b52ea6238bb2'
      )
    end
  end
end
