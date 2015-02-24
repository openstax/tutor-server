require 'rails_helper'

describe EntitySs::CreateUser do
  it "returns a newly created user entity" do
    result = nil

    expect {
      result = EntitySs::CreateUser.call
    }.to change{EntitySs::User.count}.by(1)

    expect(result.errors).to be_empty
    expect(result.outputs.user).to eq(EntitySs::User.all.last)
  end
end
