require 'rails_helper'

RSpec.describe GetCourseProfile, type: :routine do
  it 'finds a course profile by entity course id' do
    entity_course = FactoryGirl.create :entity_course
    profile = GetCourseProfile[course: entity_course]

    expect(profile.entity_course_id).to eq(entity_course.id)
  end
end
