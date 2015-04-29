require 'rails_helper'

RSpec.describe CourseProfile::GetProfile do
  it 'outputs the profile by entity course id' do
    course = CreateCourse[]
    profile = CourseProfile::GetProfile[course: course]
    expect(profile.course_id).to eq(course.id)
  end
end
