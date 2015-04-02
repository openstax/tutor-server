require 'rails_helper'

RSpec.describe CourseContent::GetCourseBooks, :type => :routine do

  let!(:course) { Entity::Course.create! }
  let!(:book1)  { Entity::Book.create! }
  let!(:book2)  { Entity::Book.create! }

  it "finds course books" do
    CourseContent::AddBookToCourse.call(course: course, book: book1)
    CourseContent::AddBookToCourse.call(course: course, book: book2)

    expect(result = CourseContent::GetCourseBooks.call(course: course)).not_to have_routine_errors
    expect(result.outputs.books).to match a_collection_containing_exactly book1, book2
  end
end
