require 'rails_helper'

describe Entity::CreateRole do
  it "returns a newly created role entity" do
    result = nil

    expect {
      result = Entity::CreateRole.call
    }.to change{Entity::Models::Role.count}.by(1)

    expect(result.errors).to be_empty
    expect(result.outputs.role).to eq(Entity::Models::Role.all.last)
  end
end
