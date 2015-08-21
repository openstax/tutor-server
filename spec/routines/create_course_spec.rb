require 'rails_helper'

describe CreateCourse do
  it "creates a new course" do
    result = CreateCourse.call(name: 'Unnamed')
    expect(result.errors).to be_empty

    course = result.outputs.course

    expect(course).to be_a Entity::Course
    expect(course.course_assistants.count).to eq 3
  end
end
