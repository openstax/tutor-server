require 'rails_helper'

RSpec.describe User, :type => :model do
  it { is_expected.to belong_to(:account) }
  it { is_expected.to have_many(:groups_as_member) }
  it { is_expected.to have_many(:groups_as_owner) }
  it { is_expected.to have_one(:administrator).dependent(:destroy) }
  it { is_expected.to have_many(:educators).dependent(:destroy) }
  it { is_expected.to have_many(:students).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:account) }
  it { is_expected.to validate_presence_of(:exchange_identifier) }

  it 'must enforce that one account is only used by one user' do
    user1 = FactoryGirl.create(:user)
    user2 = FactoryGirl.create(:user)
    user2.account = user1.account
    expect(user2).to_not be_valid
  end

  [:username, :first_name, :last_name, :full_name, :title, :name, :casual_name].each do |method|
    it { is_expected.to delegate_method(method).to(:account) }
  end
  
  [:first_name=, :last_name=, :full_name=, :title=].each do |method|
    it { is_expected.to delegate_method(method).to(:account).with_arguments('foo') }
  end

  it 'is human' do expect(User.new.is_human?).to be_truthy end
  it 'is not an application' do expect(User.new.is_application?).to be_falsy end
  it 'doesn\'t start deleted' do expect(User.new.is_deleted?).to be_falsy end

  it 'still exists after deletion' do
    user1 = FactoryGirl.create(:user)
    id = user1.id
    user1.delete
    expect(User.where(id: id).one?).to be_truthy
    expect(user1.is_deleted?).to be_truthy
  end

  it 'still exists after destroy' do
    user1 = FactoryGirl.create(:user)
    id = user1.id
    user1.destroy
    expect(User.where(id: id).one?).to be_truthy
    expect(user1.is_deleted?).to be_truthy
  end

  it 'can be undeleted' do
    user1 = FactoryGirl.create(:user)
    id = user1.id
    user1.destroy
    expect(user1.is_deleted?).to be_truthy
    user1.undelete
    expect(user1.is_deleted?).to be_falsy
  end
end

