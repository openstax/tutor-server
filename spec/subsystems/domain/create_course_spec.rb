require 'rails_helper'

describe Domain::CreateCourse do
  it "creates a new course" do
    result = Domain::CreateCourse.call
    expect(result.errors).to be_empty
    expect(result.outputs.course).to_not be_nil
    expect(result.outputs.course.class).to eq(Entity::Models::Course)
  end
end
