require 'rails_helper'

RSpec.describe SuggestionAccessPolicy, type: :access_policy do

  let(:anon) { User::Models::Profile.anonymous }
  let(:user) { FactoryBot.create(:user_profile) }


  it 'cannot be created by anonymous users' do
    expect(
      SuggestionAccessPolicy.action_allowed?(:create, anon, User::Models::Suggestion)
    ).to eq false
  end

  it 'cannot be created by student users' do
    user.account.role = :student
    expect(
      SuggestionAccessPolicy.action_allowed?(:create, user, User::Models::Suggestion)
    ).to eq false
  end

end
