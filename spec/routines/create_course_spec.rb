require 'rails_helper'

describe CreateCourse do
  it "creates a new course" do
    result = CreateCourse[name: 'Unnamed']
    expect(result.errors).to be_empty
    expect(result.outputs.course).to_not be_nil
    expect(result.outputs.course.class).to eq(Entity::Course)
  end
end
