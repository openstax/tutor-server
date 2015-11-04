require 'rails_helper'

describe Api::V1::Cc::TasksController, type: :routing, api: true, version: :v1 do

  describe '/api/cc/tasks/:cnx_book_id/:cnx_page_id' do
    it "routes to #show" do
      expect(get '/api/cc/tasks/abc/123').to(
        route_to('api/v1/cc/tasks#show', format: 'json', cnx_book_id: 'abc', cnx_page_id: '123')
      )
    end
  end

end
