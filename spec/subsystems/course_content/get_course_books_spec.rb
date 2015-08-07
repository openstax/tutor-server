require 'rails_helper'

RSpec.describe CourseContent::GetCourseBooks, type: :routine do

  let!(:course) { Entity::Course.create! }
  let!(:book1)  { FactoryGirl.create(:content_book) }
  let!(:book2)  { FactoryGirl.create(:content_book) }
  let!(:eco1)   { book1.ecosystem }
  let!(:eco2)   { book2.ecosystem }

  it "finds course books" do
    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco1)
    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco2)

    expect(result = CourseContent::GetCourseBooks.call(course: course)).not_to have_routine_errors
    expect(result.outputs.books).to match a_collection_containing_exactly book1, book2
  end
end
