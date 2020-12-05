require 'rails_helper'

RSpec.describe ExerciseAccessPolicy, type: :access_policy do
  let(:author)   { FactoryBot.create :user_profile }
  let(:exercise) { FactoryBot.create :content_exercise, profile: author }

  # action, requestor are set in contexts
  subject(:allowed) { described_class.action_allowed?(action, requestor, exercise) }

  context 'anonymous users' do
    let(:requestor) { User::Models::Profile.anonymous }

    context '#delete' do
      let(:action) { :delete }

      it { should eq false }
    end
  end

  context 'random users' do
    let(:requestor) { FactoryBot.create(:user_profile) }

    context '#delete' do
      let(:action) { :delete }

      it { should eq false }
    end
  end

  context 'exercise author' do
    let(:requestor) { author }

    context '#delete' do
      let(:action) { :delete }

      it { should eq true }
    end
  end
end
