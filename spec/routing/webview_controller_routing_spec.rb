require "rails_helper"

describe WebviewController, :type => :routing do

  describe "/blahblahblah" do
    it "routes to #index when format is html" do
      expect(get '/blahblahblah.html').to route_to('webview#index', other: "blahblahblah", format: 'html')
    end

    it "finds no route when format is not html" do
      expect(get '/blahblahblah.text').not_to be_routable
      expect(get '/blahblahblah.json').not_to be_routable
    end
  end

end
