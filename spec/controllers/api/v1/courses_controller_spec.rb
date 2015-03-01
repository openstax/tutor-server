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
      # expect(response.code).to eq '200'
      # expect(response.body_as_hash).to include(id: task_1.id)
      # expect(response.body_as_hash).to include(title: 'A Task Title')
      # expect(response.body_as_hash).to have_key(:steps)
      # expect(response.body_as_hash[:steps][0]).to include(type: 'reading')
      # expect(response.body_as_hash[:steps][1]).to include(type: 'exercise')
    end
  end

end
