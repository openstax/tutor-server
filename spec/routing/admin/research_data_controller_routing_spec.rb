require "rails_helper"

RSpec.describe Admin::ResearchDataController, type: :routing do

  describe "GET /admin/research_data" do
    it "routes to #index" do
      expect(get '/admin/research_data').to route_to('admin/research_data#index')
    end
  end

  describe "POST /admin/research_data" do
    it "routes to #create" do
      expect(post '/admin/research_data').to route_to('admin/research_data#create')
    end
  end

end
