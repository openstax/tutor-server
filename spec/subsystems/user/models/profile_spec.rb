require 'rails_helper'

RSpec.describe User::Models::Profile, type: :model do

  subject(:profile) { FactoryBot.create(:user_profile) }

  it { is_expected.to belong_to(:account) }
  it { is_expected.to have_many(:groups_as_member) }
  it { is_expected.to have_many(:groups_as_owner) }
  it { is_expected.to have_one(:administrator).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:account) }

  it 'must enforce that one account is only used by one user' do
    profile_2 = FactoryBot.build(:user_profile)
    profile_2.account = profile.account
    expect(profile_2).to_not be_valid
  end

  [:username, :first_name, :last_name, :full_name, :title,
   :name, :casual_name, :faculty_status, :role, :school_type].each do |method|
    it { is_expected.to delegate_method(method).to(:account) }
  end

  [:first_name=, :last_name=, :full_name=, :title=].each do |method|
    it { is_expected.to delegate_method(method).to(:account).with_arguments('foo') }
  end

  it 'enforces length of ui_settings' do
    profile = FactoryBot.build(:user_profile)
    profile.ui_settings = {test: ('a' * 10_001)}
    expect(profile).to_not be_valid
    expect(profile.errors[:ui_settings].to_s).to include 'too long'
  end

end
