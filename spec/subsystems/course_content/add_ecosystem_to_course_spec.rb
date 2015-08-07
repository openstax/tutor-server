require 'rails_helper'

RSpec.describe CourseContent::AddEcosystemToCourse, type: :routine do

  let!(:course) { Entity::Course.create! }
  let!(:eco1)   { Ecosystem::Ecosystem.create! }
  let!(:eco2)   { Ecosystem::Ecosystem.create! }

  it "adds an ecosystem to a course when the ecosystem is not already there" do
    result = nil
    expect{result = CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco1)}
      .to change{CourseContent::Models::CourseEcosystem.count}.by (1)
    expect(result).not_to have_routine_errors

    expect{result = CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco2)}
      .to change{CourseContent::Models::CourseEcosystem.count}.by (1)
    expect(result).not_to have_routine_errors

    expect(course.ecosystems.order(:created_at)).to eq [eco1, eco2]
  end

  it "doesn't add an ecosystem that is already there to a course" do
    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco1)

    result = nil
    expect{result = CourseContent::AddEcosystemToCourse.call(course: course, book: eco1)}
      .not_to change{CourseContent::Models::CourseEcosystem.count}
    expect(result).to have_routine_errors

    expect(course.ecosystems).to eq [eco1]
  end

  it 'removes all other ecosystems if the flag is set' do
    result = CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco1,
                                                      remove_other_ecosystems: true)
    expect(result).not_to have_routine_errors

    expect(course.ecosystems).to eq [eco1]

    result = CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: eco2,
                                                      remove_other_ecosystems: true)
    expect(result).not_to have_routine_errors

    expect(course.ecosystems).to eq [eco2]
  end

end
