require 'rails_helper'

RSpec.describe GetCourse do
  it 'finds a course profile by entity course id' do
    entity_course = CreateCourse.call.outputs.course
    course = GetCourse.call(entity_course.id).outputs.course

    expect(course.course_id).to eq(entity_course.id)
  end
end
