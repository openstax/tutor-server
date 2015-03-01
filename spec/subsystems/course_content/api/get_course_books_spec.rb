require 'rails_helper'

RSpec.describe CourseContent::Api::GetCourseBooks, :type => :routine do

  let!(:course) { Entity::CreateCourse.call.outputs.course }
  let!(:book1)  { Entity::CreateBook.call.outputs.book }
  let!(:book2)  { Entity::CreateBook.call.outputs.book }

  
 
end