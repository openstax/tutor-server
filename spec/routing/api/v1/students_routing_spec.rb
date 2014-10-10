require "rails_helper"

module Api::V1
  RSpec.describe KlassesController, :type => :routing, api: true, version: :v1 do
    describe "routing" do

      it "routes to #index" do
        expect(get("/api/schools/1/courses/1/klasses/1/students")).to(
          route_to("api/v1/students#index", format: "json", school_id: "1",
                                            course_id: "1", klass_id: "1"))
      end

      it "routes to #show" do
        expect(get("/api/schools/1/courses/1/klasses/1/students/1")).to(
          route_to("api/v1/students#show", format: "json", school_id: "1",
                                           course_id: "1", klass_id: "1", id: "1"))
      end

      it "routes to #create" do
        expect(post("/api/schools/1/courses/1/klasses/1/students")).to(
          route_to("api/v1/students#create", format: "json", school_id: "1",
                                             course_id: "1", klass_id: "1"))
      end

      it "routes to #update" do
        expect(put("/api/schools/1/courses/1/klasses/1/students/1")).to(
          route_to("api/v1/students#update", format: "json", school_id: "1",
                                             course_id: "1", klass_id: "1", id: "1"))
      end

      it "routes to #destroy" do
        expect(delete("/api/schools/1/courses/1/klasses/1/students/1")).to(
          route_to("api/v1/students#destroy", format: "json", school_id: "1",
                                              course_id: "1", klass_id: "1", id: "1"))
      end

    end
  end
end
