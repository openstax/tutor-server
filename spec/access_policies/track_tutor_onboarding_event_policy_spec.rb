require 'rails_helper'

RSpec.describe TrackTutorOnboardingEventPolicy, type: :access_policy do

  let(:anon) { User::User.anonymous }
  let(:user) { FactoryGirl.create(:user) }


  it 'cannot be accessed by non-confirmed-faculty' do
    expect(TrackTutorOnboardingEventPolicy.action_allowed?('created_real_course', anon,
                                                           TrackTutorOnboardingEvent)).to eq false
  end

  context 'accessed by confirmed faculty' do
    before(:each) { user.account.faculty_status = :confirmed_faculty }

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
