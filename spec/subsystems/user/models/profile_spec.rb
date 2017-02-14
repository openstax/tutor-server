require 'rails_helper'

RSpec.describe User::Models::Profile, type: :model do

  subject(:profile) { FactoryGirl.create(:user_profile) }

  it { is_expected.to belong_to(:account) }
  it { is_expected.to have_many(:groups_as_member) }
  it { is_expected.to have_many(:groups_as_owner) }
  it { is_expected.to have_one(:administrator).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:account) }

  it 'must enforce that one account is only used by one user' do
    profile_2 = FactoryGirl.build(:user_profile)
    profile_2.account = profile.account
    expect(profile_2).to_not be_valid
  end

  [:username, :first_name, :last_name, :full_name, :title,
   :name, :casual_name, :faculty_status].each do |method|
    it { is_expected.to delegate_method(method).to(:account) }
  end

  [:first_name=, :last_name=, :full_name=, :title=].each do |method|
    it { is_expected.to delegate_method(method).to(:account).with_arguments('foo') }
  end

  it 'enforces length of ui_settings' do
    profile = FactoryGirl.build(:user_profile)
    profile.ui_settings = {test: ('a' * 1500)}
    expect(profile).to_not be_valid
    expect(profile.errors[:ui_settings].to_s).to include 'too long'
  end

  it 'requires prevsious settings to be valid when changed' do
    profile = FactoryGirl.create(:user_profile, ui_settings: {'one' => 1})
    profile.ui_settings = {test: true}
    expect(profile.save).to be false
    expect(profile.errors[:previous_ui_settings].to_s).to include 'out-of-band update detected'
    profile.previous_ui_settings = {'one' => 1}
    expect(profile.save).to be true
    expect(profile.errors[:previous_ui_settings]).to be_empty
  end

end
