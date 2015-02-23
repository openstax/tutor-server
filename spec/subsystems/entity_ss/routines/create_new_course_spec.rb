require 'rails_helper'

describe EntitySs::CreateNewCourse do
  it "returns a newly created course entity" do
    result = nil

    expect {
      result = EntitySs::CreateNewCourse.call
    }.to change{EntitySs::Course.count}.by(1)

    expect(result.errors).to be_empty
    expect(result.outputs.course).to eq(EntitySs::Course.all.last)
  end
end
