require 'rails_helper'

RSpec.describe User::Models::Profile, type: :model do

  subject(:profile) { FactoryGirl.create(:user_profile) }

  it { is_expected.to belong_to(:account) }
  it { is_expected.to have_many(:groups_as_member) }
  it { is_expected.to have_many(:groups_as_owner) }
  it { is_expected.to have_one(:administrator).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:account) }
  it { is_expected.to validate_presence_of(:exchange_read_identifier) }
  it { is_expected.to validate_presence_of(:exchange_write_identifier) }

  it 'must enforce that one account is only used by one user' do
    profile_2 = FactoryGirl.build(:user_profile)
    profile_2.account = profile.account
    expect(profile_2).to_not be_valid
  end

  [:username, :first_name, :last_name, :full_name, :title, :name, :casual_name].each do |method|
    it { is_expected.to delegate_method(method).to(:account) }
  end

  [:first_name=, :last_name=, :full_name=, :title=].each do |method|
    it { is_expected.to delegate_method(method).to(:account).with_arguments('foo') }
  end

end
