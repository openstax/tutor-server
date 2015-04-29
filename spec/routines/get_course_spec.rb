require 'rails_helper'

RSpec.describe GetCourse do
  it 'finds a course profile by entity course id' do
    entity_course = CreateCourse[]
    course = GetCourse[course: entity_course]

    expect(course.course_id).to eq(entity_course.id)
  end
end
