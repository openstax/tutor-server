require 'rails_helper'

RSpec.describe "Session to Token", type: :request do

  it "returns a token for a logged-in session user" do
    user = FactoryGirl.create(:user)
    stub_current_user(user, Doorkeeper::TokensController)

    post('/oauth/token', grant_type: 'session')

    expect(response.body_as_hash).to include(
      access_token: be_kind_of(String),
      token_type: "bearer",
    )
  end

  it "does not return a token for an anonymous user" do
    anon = FactoryGirl.create(:anonymous_user)

    post('/oauth/token', grant_type: 'session')

    expect(response.body_as_hash).to include(
      error: "invalid_grant",
    )
  end

end
