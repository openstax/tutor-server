require "rails_helper"

RSpec.describe Admin::SalesforceController, type: :routing do

  describe "/auth/salesforce/callback" do
    it "routes to #callback" do
      expect(get '/auth/salesforce/callback').to route_to('admin/salesforce#callback')
    end
  end

end
