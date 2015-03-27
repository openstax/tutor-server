require 'rails_helper'

describe Entity::CreateUser do
  it "returns a newly created user entity" do
    result = nil

    expect {
      result = Entity::CreateUser.call
    }.to change{Entity::Models::User.count}.by(1)

    expect(result.errors).to be_empty
    expect(result.outputs.user).to eq(Entity::Models::User.all.last)
  end
end
