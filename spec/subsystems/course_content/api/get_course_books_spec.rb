require 'rails_helper'

RSpec.describe CourseContent::Api::GetCourseBooks, :type => :routine do

  let!(:course) { Entity::CreateCourse.call.outputs.course }
  let!(:book1)  { Entity::CreateBook.call.outputs.book }
  let!(:book2)  { Entity::CreateBook.call.outputs.book }

  it "finds course books" do
    CourseContent::Api::AddBookToCourse.call(course: course, book: book1)
    CourseContent::Api::AddBookToCourse.call(course: course, book: book2)

    expect(result = CourseContent::Api::GetCourseBooks.call(course: course)).not_to have_routine_errors
    expect(result.outputs.books).to match a_collection_containing_exactly book1, book2
  end
end