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

    expect(course.books.order(:created_at)).to eq [book1, book2]
  end

  it "doesn't add a book to a course that is already there" do
    CourseContent::AddBookToCourse.call(course: course, book: book1)

    result = nil
    expect{result = CourseContent::AddBookToCourse.call(course: course, book: book1)}
      .to change{CourseContent::Models::CourseBook.count}.by (0)
    expect(result).to have_routine_errors

    expect(course.books).to eq [book1]
  end

  it 'removes all other books if the flag is set' do
    result = CourseContent::AddBookToCourse.call(course: course, book: book1, remove_other_books: true)
    expect(result).not_to have_routine_errors

    expect(course.books).to eq [book1]

    result = CourseContent::AddBookToCourse.call(course: course, book: book2, remove_other_books: true)
    expect(result).not_to have_routine_errors

    expect(course.books).to eq [book2]
  end

end
