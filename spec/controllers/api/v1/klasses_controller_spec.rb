require "rails_helper"

module Api::V1
  RSpec.describe KlassesController, :type => :controller, :api => true, :version => :v1 do

    let!(:application)    { FactoryGirl.create :doorkeeper_application }
    let!(:user)           { FactoryGirl.create :user }
    let!(:user_token)     { FactoryGirl.create :doorkeeper_access_token, 
                                               application: application, 
                                               resource_owner_id: user.id }
    let!(:course)         { FactoryGirl.create :course }
    let!(:course_manager) { FactoryGirl.create :course_manager, course: course, user: user }
    let!(:klass)          { FactoryGirl.build :klass, course: course }

    let!(:params)         { {course_id: course.id, school_id: course.school_id} }

    context "GET show" do
      it "returns the klass that matches the given ID" do
        klass.save!
        api_get :show, user_token, parameters: params.merge(id: klass.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(Api::V1::KlassRepresenter.new(klass).to_json)
      end
    end

    context "POST create" do
      it "creates a new klass under the given course" do
        attributes = JSON.parse(Api::V1::KlassRepresenter.new(klass).to_json)
        expect { api_post :create, user_token, parameters: params,
                          raw_post_data: attributes }.to(
          change(Klass, :count).by(1))
        expect(response).to have_http_status(:created)
        klass = Klass.last
        result_json = Api::V1::KlassRepresenter.new(klass).to_json
        result = JSON.parse(result_json)
        expect(result).to eq attributes
        expect(response.body).to eq result_json
      end
    end

    context "PATCH update" do
      it "updates the class that matches the given ID" do
        klass.save!
        klass.ends_at = Time.now + 10.years
        attributes = JSON.parse(Api::V1::KlassRepresenter.new(klass).to_json)
        api_patch :update, user_token, parameters: params.merge(id: klass.id),
                  raw_post_data: attributes
        expect(response).to have_http_status(:no_content)
        klass.reload
        result = JSON.parse(Api::V1::KlassRepresenter.new(klass).to_json)
        expect(result).to eq attributes
      end
    end

    context "DELETE destroy" do
      it "deletes the class that matches the given ID" do
        klass.save!
        expect { api_delete :destroy, user_token,
                            parameters: params.merge(id: klass.id) }.to(
          change(Klass, :count).by(-1))
        expect(response).to have_http_status(:no_content)
        expect(Klass.where(id: klass.id)).not_to exist
      end
    end

  end
end
