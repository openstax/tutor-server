require 'rails_helper'

RSpec.describe UserProfile::MakeAdministrator do
  it 'makes a user an administrator' do
    user = Entity::User.create!
    profile = FactoryGirl.create(:user_profile, entity_user: user)

    expect(profile.administrator).to be_nil

    described_class[user: user]

    expect(profile.reload.administrator).not_to be_nil
  end
end
