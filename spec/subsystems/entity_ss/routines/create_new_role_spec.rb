require 'rails_helper'

describe EntitySs::CreateNewRole do
  it "returns a newly created role entity" do
    result = nil

    expect {
      result = EntitySs::CreateNewRole.call
    }.to change{EntitySs::Role.count}.by(1)

    expect(result.errors).to be_empty
    expect(result.outputs.role).to eq(EntitySs::Role.all.last)
  end
end
