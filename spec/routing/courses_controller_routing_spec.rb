require "rails_helper"

RSpec.describe CoursesController, type: :routing do
  context "GET /teach/:teach_token(/:ignore)" do
    it "routes to #teach" do
      expect(get '/teach/42/everything').to(
        route_to 'courses#teach', teach_token: '42', ignore: 'everything'
      )
    end
  end
end
