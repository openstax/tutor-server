require 'rails_helper'

RSpec.describe User::Models::ContentAnalyst, type: :model do

  subject(:content_analyst) { FactoryBot.create(:user_content_analyst) }

  it { is_expected.to belong_to(:profile) }

  it { is_expected.to validate_uniqueness_of(:profile) }

  let(:anon) { User::Models::AnonymousProfile.instance }
  let(:profile) { FactoryBot.create(:user_profile) }

  it 'cannot refer to the anonymous profile' do
    expect{described_class.create(profile: anon)}.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'cannot exist twice for the same profile' do
    expect(described_class.new(profile: content_analyst.profile)).to_not be_valid
  end

  it 'can be added for a non-content-analyst' do
    expect(described_class.create(profile: profile)).to be_valid
  end

end
