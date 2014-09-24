require 'rails_helper'

RSpec.describe Administrator, :type => :model do
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



