require 'rails_helper'

RSpec.describe User::Models::Administrator, type: :model do

  subject(:admin) { FactoryBot.create(:user_administrator) }

  it { is_expected.to belong_to(:profile) }

  it { is_expected.to validate_presence_of(:profile) }

  it { is_expected.to validate_uniqueness_of(:profile) }

  let(:anon) { User::Models::AnonymousProfile.instance }
  let(:profile) { FactoryBot.create(:user_profile) }

  it 'cannot refer to the anonymous profile' do
    expect{described_class.create(profile: anon)}.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'cannot exist twice for the same profile' do
    expect(described_class.new(profile: admin.profile)).to_not be_valid
  end

  it 'can be added for a non-admin' do
    expect(described_class.create(profile: profile)).to be_valid
  end

end
