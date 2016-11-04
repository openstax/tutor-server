require "rails_helper"

RSpec.describe Admin::PeriodsController, type: :routing do

  context "DELETE /admin/periods/:id" do
    it "routes to #destroy" do
      expect(delete '/admin/periods/42').to route_to('admin/periods#destroy', id: '42')
    end
  end

  context "PUT /admin/periods/:id/restore" do
    it "routes to #restore" do
      expect(put '/admin/periods/42/restore').to route_to('admin/periods#restore', id: '42')
    end
  end

end
