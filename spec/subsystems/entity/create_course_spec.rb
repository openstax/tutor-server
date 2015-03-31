require 'rails_helper'

describe Entity::CreateCourse do
  it "returns a newly created course entity" do
    result = nil

    expect {
      result = Entity::CreateCourse.call
    }.to change{Entity::Models::Course.count}.by(1)

    expect(result.errors).to be_empty
    expect(result.outputs.course).to eq(Entity::Models::Course.all.last)
  end
end
