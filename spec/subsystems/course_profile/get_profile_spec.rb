require 'rails_helper'

RSpec.describe CourseProfile::GetProfile do
  it 'outputs the profile by entity course id' do
    course = FactoryGirl.create :entity_course
    profile = described_class[course: course]
    expect(profile.entity_course_id).to eq(course.id)
  end
end
