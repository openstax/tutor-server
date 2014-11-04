require 'rails_helper'

RSpec.describe Administrator, :type => :model do

  it { is_expected.to belong_to(:user) }

  it { is_expected.to have_many(:taskings).dependent(:destroy) }
  it { is_expected.to have_many(:tasking_plans).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:user) }

  it { is_expected.to validate_uniqueness_of(:user) }

  let!(:anon)        { AnonymousUser.instance }
  let!(:user)        { FactoryGirl.create(:user) }
  let!(:admin1) { FactoryGirl.create(:administrator) }

  it 'cannot refer to the anonymous user' do
    expect{Administrator.create(user: anon)}.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'cannot exist twice for the same user' do
    expect(Administrator.new(user: admin1.user)).to_not be_valid
  end

  it 'can be added for a non-admin' do
    expect(Administrator.create(user: user)).to be_valid
  end
end



