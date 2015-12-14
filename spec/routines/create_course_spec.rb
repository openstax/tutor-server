require 'rails_helper'

describe CreateCourse, type: :routine do
  it "creates a new course" do
    result = CreateCourse.call(name: 'Unnamed')
    expect(result.errors).to be_empty

    course = result.course

    expect(course).to be_a Entity::Course
    expect(course.course_assistants.count).to eq 4
  end

  it 'adds a unique registration code for the teacher' do
    allow(SecureRandom).to receive(:hex) { 'abc123' }

    course = CreateCourse.call(name: 'Reg Code Course')

    expect(course.teacher_join_token).to eq('abc123')
  end
end
