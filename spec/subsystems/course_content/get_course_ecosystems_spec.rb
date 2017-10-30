require 'rails_helper'

RSpec.describe CourseContent::GetCourseEcosystems, type: :routine do

  let(:course)       { FactoryGirl.create :course_profile_course, :without_ecosystem }
  let(:content_eco1) { FactoryGirl.create :content_ecosystem }
  let(:eco1)         { Content::Ecosystem.new strategy: content_eco1.wrap }
  let(:content_eco2) { FactoryGirl.create :content_ecosystem }
  let(:eco2)         { Content::Ecosystem.new strategy: content_eco2.wrap }

  it "finds course ecosystems" do
    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco1)
    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco2)

    expect(result = CourseContent::GetCourseEcosystems.call(course: course)).not_to(
      have_routine_errors
    )
    expect(result.outputs.ecosystems).to match a_collection_containing_exactly eco1, eco2
  end
end
