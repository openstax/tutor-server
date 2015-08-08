require 'rails_helper'

RSpec.describe CourseContent::GetCourseEcosystems, type: :routine do

  let!(:course) { Entity::Course.create! }
  let!(:eco1)   { book1.ecosystem }
  let!(:eco2)   { book2.ecosystem }

  it "finds course ecosystems" do
    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco1)
    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco2)

    expect(result = CourseContent::GetCourseEcosystems.call(course: course)).not_to have_routine_errors
    expect(result.outputs.ecosystems).to match a_collection_containing_exactly eco1, eco2
  end
end
