require 'rails_helper'

RSpec.describe TrackTutorOnboardingEventPolicy, type: :access_policy do

  let(:anon) { User::Models::Profile.anonymous }
  let(:user) { FactoryBot.create(:user_profile) }


  it 'cannot be accessed by anonymous users' do
    expect(TrackTutorOnboardingEventPolicy.action_allowed?('created_real_course', anon,
                                                           TrackTutorOnboardingEvent)).to eq false
  end

  it 'cannot be accessed by student users' do
    user.account.role = :student
    expect(TrackTutorOnboardingEventPolicy.action_allowed?('created_real_course', user,
                                                           TrackTutorOnboardingEvent)).to eq false
  end

  context 'accessed by a teacher' do
    before(:each) { user.account.role = :instructor }

    it 'rejects invalid events' do
      expect(TrackTutorOnboardingEventPolicy.action_allowed?('wrong_bad_incorrect', user,
                                                             TrackTutorOnboardingEvent)).to eq false
    end

    it 'succeeds with a valid event code' do
      expect(TrackTutorOnboardingEventPolicy.action_allowed?('created_real_course', user,
                                                             TrackTutorOnboardingEvent)).to eq true
    end

  end

end
