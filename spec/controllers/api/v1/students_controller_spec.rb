require "rails_helper"

module Api::V1
  RSpec.describe StudentsController, :type => :controller, :api => true, :version => :v1 do

    let!(:application) { FactoryGirl.create :doorkeeper_application }
    let!(:user)        { FactoryGirl.create :user }
    let!(:user_token)  { FactoryGirl.create :doorkeeper_access_token, 
                                            application: application, 
                                            resource_owner_id: user.id }
    let!(:klass)       { FactoryGirl.create :klass }
    let!(:educator)    { FactoryGirl.create :educator, klass: klass, user: user }
    let!(:student)     { FactoryGirl.build :student, klass: klass }

    let!(:params)      { {klass_id: klass.id, course_id: klass.course_id,
                          school_id: klass.course.school_id} }

    context "GET index" do
      it "lists the students in the given class" do
        student.save!
        api_get :index, user_token, parameters: params
        expect(response).to have_http_status(:ok)
        expected_outputs = Lev::Outputs.new(items: [student])
        expect(response.body).to eq(
          Api::V1::StudentSearchRepresenter.new(expected_outputs).to_json)
      end
    end

    context "GET show" do
      it "returns the student that matches the given ID" do
        student.save!
        api_get :show, user_token, parameters: params.merge(id: student.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(Api::V1::StudentRepresenter.new(student).to_json)
      end
    end

    context "POST create" do
      it "creates a new student under the given klass" do
        attributes = JSON.parse(Api::V1::StudentRepresenter.new(student).to_json)
        attributes["user_id"] = attributes["user"]["id"]
        attributes.delete("user")
        expect { api_post :create, user_token, parameters: params,
                          raw_post_data: attributes }.to change(Student, :count).by(1)
        expect(response).to have_http_status(:created)
        student = Student.last
        result_json = Api::V1::StudentRepresenter.new(student).to_json
        result = JSON.parse(result_json)
        expect(result["user"]["id"]).to eq attributes["user_id"]
        expect(result.except("random_education_identifier", "user")).to(
          eq attributes.except("random_education_identifier", "user_id"))
        expect(response.body).to eq result_json
      end
    end

    context "PATCH update" do
      it "updates the student that matches the given ID" do
        student.save!
        section = FactoryGirl.create(:section, klass: student.klass)
        student.section = section
        attributes = JSON.parse(Api::V1::StudentRepresenter.new(student).to_json)
        attributes["user_id"] = attributes["user"]["id"]
        attributes.delete("user")
        api_patch :update, user_token,
                  parameters: params.merge(id: student.id),
                  raw_post_data: attributes
        expect(response).to have_http_status(:no_content)
        student.reload
        expect(student.section).to eq section
        result = JSON.parse(Api::V1::StudentRepresenter.new(student).to_json)
        expect(result["user"]["id"]).to eq attributes["user_id"]
        expect(result.except("user")).to eq attributes.except("user_id")
      end
    end

    context "DELETE destroy" do
      it "deletes the student that matches the given ID" do
        student.save!
        expect { api_delete :destroy, user_token,
                            parameters: params.merge(id: student.id) }.to(
          change(Student, :count).by(-1))
        expect(response).to have_http_status(:no_content)
        expect(Student.where(id: student.id)).not_to exist
      end
    end

  end
end
