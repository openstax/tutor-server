require 'rails_helper'

RSpec.describe CourseContent::AddEcosystemToCourse, type: :routine do

  let(:course)       { FactoryBot.create :course_profile_course, :without_ecosystem }
  let(:content_eco1) { FactoryBot.create :content_ecosystem }
  let(:eco1)         { Content::Ecosystem.new strategy: content_eco1.wrap }
  let(:content_eco2) { FactoryBot.create :content_ecosystem }
  let(:eco2)         { Content::Ecosystem.new strategy: content_eco2.wrap }

  it "adds an ecosystem to a course when the ecosystem is not already there" do
    result = nil
    expect{result = CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco1)}
      .to change{course.course_ecosystems.count}.by(1)
    expect(result).not_to have_routine_errors

    expect{result = CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco2)}
      .to change{course.course_ecosystems.count}.by(1)
    expect(result).not_to have_routine_errors

    ecosystems = CourseContent::GetCourseEcosystems[course: course]
    expect(ecosystems.map(&:id)).to match_array [eco1.id, eco2.id]
  end

  it "doesn't add an ecosystem that is already there to a course" do
    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco1)

    result = nil
    expect{result = CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco1)}
      .not_to change{course.course_ecosystems.count}
    expect(result).to have_routine_errors

    ecosystems = CourseContent::GetCourseEcosystems[course: course]
    expect(ecosystems.map(&:id)).to eq [eco1.id]
  end

end
