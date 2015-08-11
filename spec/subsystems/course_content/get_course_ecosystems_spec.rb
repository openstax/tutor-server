require 'rails_helper'

RSpec.describe CourseContent::GetCourseEcosystems, type: :routine do

  let!(:course) { Entity::Course.create! }
  let!(:eco1)   { Content::Ecosystem.create!(title: 'Eco1') }
  let!(:eco2)   { Content::Ecosystem.create!(title: 'Eco2') }

  it "finds course ecosystems" do
    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco1)
    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco2)

    expect(result = CourseContent::GetCourseEcosystems.call(course: course)).not_to have_routine_errors
    expect(result.outputs.ecosystems).to match a_collection_containing_exactly eco1, eco2
  end
end
