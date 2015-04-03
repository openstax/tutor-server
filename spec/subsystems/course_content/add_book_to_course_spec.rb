require 'rails_helper'

RSpec.describe CourseContent::AddBookToCourse, :type => :routine do

  let!(:course) { Entity::Course.create! }
  let!(:book1)  { Entity::Book.create! }
  let!(:book2)  { Entity::Book.create! }

  it "adds a book to a course when the book is not already there" do
    result = nil
    expect{result = CourseContent::AddBookToCourse.call(course: course, book: book1)}
      .to change{CourseContent::Models::CourseBook.count}.by (1)
    expect(result).not_to have_routine_errors

    expect{result = CourseContent::AddBookToCourse.call(course: course, book: book2)}
      .to change{CourseContent::Models::CourseBook.count}.by (1)
    expect(result).not_to have_routine_errors
  end

  it "doesn't add a book to a course that is already there" do
    CourseContent::AddBookToCourse.call(course: course, book: book1)

    result = nil
    expect{result = CourseContent::AddBookToCourse.call(course: course, book: book1)}
      .to change{CourseContent::Models::CourseBook.count}.by (0)
    expect(result).to have_routine_errors
  end

end
