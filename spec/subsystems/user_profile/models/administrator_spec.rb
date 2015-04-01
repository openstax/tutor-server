require 'rails_helper'

RSpec.describe UserProfile::Models::Administrator, :type => :model do

  it { is_expected.to belong_to(:profile) }

  it { is_expected.to validate_presence_of(:profile) }

  it { is_expected.to validate_uniqueness_of(:profile) }

  let!(:anon) { UserProfile::Models::AnonymousUser.instance }
  let!(:profile) { FactoryGirl.create(:profile) }
  let!(:admin1) { FactoryGirl.create(:administrator) }

  it 'cannot refer to the anonymous profile' do
    expect{described_class.create(profile: anon)}.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'cannot exist twice for the same profile' do
    expect(described_class.new(profile: admin1.profile)).to_not be_valid
  end

  it 'can be added for a non-admin' do
    expect(described_class.create(profile: profile)).to be_valid
  end
end
