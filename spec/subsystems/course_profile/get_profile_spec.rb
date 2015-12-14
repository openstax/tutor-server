require 'rails_helper'

RSpec.describe CourseProfile::GetProfile do
  it 'outputs the profile by entity course id' do
    course = CreateCourse.call(name: 'anything')
    profile = CourseProfile::GetProfile.call(course: course)
    expect(profile.entity_course_id).to eq(course.id)
  end
end
