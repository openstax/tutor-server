require 'rails_helper'

RSpec.describe Api::V1::CoursesController, :type => :controller, :api => true, :version => :v1  do
  
  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:user_1)          { FactoryGirl.create :user }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token, 
                                              application: application, 
                                              resource_owner_id: user_1.id }

  let!(:user_2)          { FactoryGirl.create :user }
  let!(:user_2_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_2.id }

  let!(:userless_token)  { FactoryGirl.create :doorkeeper_access_token,
                                              application: application }

  let!(:course) { Entity::CreateCourse.call.outputs.course }

  describe "#readings" do
    it "should work on the happy path" do
      root_book_part = FactoryGirl.create(:content_book_part, :standard_contents_1)
      CourseContent::Api::AddBookToCourse.call(course: course, book: root_book_part.book)
    
      api_get :readings, user_1_token, parameters: {id: course.id}

      expect(response).to have_http_status(:success)
      expect(response.body_as_hash).to eq([{
        id: 2,
        title: 'unit 1',
        type: 'part',
        children: [
          {
            id: 3, 
            title: 'chapter 1',
            type: 'part',
            children: [
              {
                id: 1,
                title: 'first page',
                type: 'page'
              },
              {
                id: 2,
                title: 'second page',
                type: 'page'
              }
            ]
          },
          {
            id: 4,
            title: 'chapter 2',
            type: 'part',
            children: [
              {
                id: 3, 
                title: 'third page',
                type: 'page'
              }
            ]
          }
        ]      
      }])

    end
  end

  describe "#plans" do
    it "should work on the happy path" do
      task_plan = FactoryGirl.create(:task_plan, owner: course)
    
      api_get :plans, user_1_token, parameters: {id: course.id}

      expect(response).to have_http_status(:success)
      expect(response.body).to(
        eq({ total_count: 1,
             items: [Api::V1::TaskPlanRepresenter.new(task_plan)] }.to_json)
      )

    end
  end

end
