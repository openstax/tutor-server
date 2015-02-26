require 'rails_helper'

describe Domain::CreateUser do
  it "creates a new user" do
    result = Domain::CreateUser.call
    expect(result.errors).to be_empty
    expect(result.outputs.user).to_not be_nil
    expect(result.outputs.user.class).to eq(Entity::User)
  end
end
