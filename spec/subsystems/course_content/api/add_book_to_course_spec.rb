require 'rails_helper'

RSpec.describe CourseContent::Api::AddBookToCourse, :type => :routine do

  let!(:course) { Entity::CreateCourse.call.outputs.course }
  let!(:book1)  { Entity::CreateBook.call.outputs.book }
  let!(:book2)  { Entity::CreateBook.call.outputs.book }

  it "adds a book to a course when the book is not already there" do
    result = nil
    expect{result = CourseContent::Api::AddBookToCourse.call(course: course, book: book1)}
      .to change{CourseContent::CourseBook.count}.by (1)
    expect(result).not_to have_routine_errors

    expect{result = CourseContent::Api::AddBookToCourse.call(course: course, book: book2)}
      .to change{CourseContent::CourseBook.count}.by (1)
    expect(result).not_to have_routine_errors
  end

  it "doesn't add a book to a course that is already there" do
    CourseContent::Api::AddBookToCourse.call(course: course, book: book1)

    result = nil
    expect{result = CourseContent::Api::AddBookToCourse.call(course: course, book: book1)}
      .to change{CourseContent::CourseBook.count}.by (0)
    expect(result).to have_routine_errors
  end
 
end