require "rails_helper"

RSpec.describe Admin::CoursesController, type: :routing do

  describe "DELETE /admin/courses/:course_id" do
    it "routes to #destroy" do
      expect(delete '/admin/courses/42').to route_to('admin/courses#destroy', id: '42')
    end
  end

end
