require 'rails_helper'

RSpec.describe User::SearchUsers, type: :routine do
  before(:all) do
    @user_1 = FactoryBot.create :user_profile,  first_name: 'John',
                                                last_name: 'Stravinsky',
                                                username: 'jstrav'

    @user_2 = FactoryBot.create :user_profile, first_name: 'Mary',
                                               last_name: 'Mighty',
                                               full_name: 'Mary Mighty',
                                               username: 'mary'

    @user_3 = FactoryBot.create :user_profile, first_name: 'John',
                                               last_name: 'Stead',
                                               username: 'jstead'

    @user_4 = FactoryBot.create :user_profile, first_name: 'Bob',
                                               last_name: 'JST',
                                               username: 'bigbear'
  end

  it 'should match based on username' do
    users = described_class.call(query: 'username:jstra').outputs.items
    expect(users).to eq [@user_1]
  end

  it 'should ignore leading wildcards on username searches' do
    users = described_class.call(query: 'username:%rav').outputs.items
    expect(users).to eq []
  end

  it 'should match based on one first name' do
    users = described_class.call(query: 'first_name:"John"').outputs.items
    expect(users).to eq [@user_3, @user_1]
  end

  it 'should match based on one full name' do
    users = described_class.call(query: 'full_name:"Mary Mighty"').outputs.items
    expect(users).to eq [@user_2]
  end

  it 'should match based on id (openstax_uid)' do
    users = described_class.call(query: "id:#{@user_3.account.openstax_uid}").outputs.items
    expect(users).to eq [@user_3]
  end

  it 'should match based on uuid' do
    users = described_class.call(query: "uuid:#{@user_3.account.uuid}").outputs.items
    expect(users).to eq [@user_3]
  end

  it 'should match based on support_identifier' do
    users = described_class.call(query: "support_identifier:#{@user_3.account.support_identifier}").outputs.items
    expect(users).to eq [@user_3]
  end

  it 'should return all results if the query is empty' do
    users = described_class.call(query: '').outputs.items
    expect(users).to eq [@user_4, @user_2, @user_3, @user_1]
  end

  it 'should match any field when no prefix given' do
    users = described_class.call(query: 'jst').outputs.items
    expect(users).to eq [@user_4, @user_3, @user_1]
  end

  it 'should match any field when no prefix given and intersect when prefix given' do
    users = described_class.call(query: 'jst username:jst').outputs.items
    expect(users).to eq [@user_3, @user_1]
  end

  it 'shouldn\'t allow users to add their own wildcards' do
    users = described_class.call(query: "username:'%ar'").outputs.items
    expect(users).to eq []
  end

  it 'should gather comma-separated unprefixed search terms' do
    users = described_class.call(query: 'john,mighty').outputs.items
    expect(users).to eq [@user_2, @user_3, @user_1]
  end

  it 'should not gather space-separated unprefixed search terms' do
    users = described_class.call(query: 'john mighty').outputs.items
    expect(users).to eq []
  end

  context 'pagination and sorting' do
    let!(:billy_users) do
      (0..45).to_a.map do |ii|
        FactoryBot.create :user_profile, first_name: "Billy#{(45-ii).to_s.rjust(2, '0')}",
                                 last_name: "Bob_#{ii.to_s.rjust(2, '0')}",
                                 username: "billy_#{ii.to_s.rjust(2, '0')}"
      end
    end

    it 'should return the first page of values by default when requested' do
      users = described_class.call(query: 'username:billy', per_page: 20).outputs.items
      expect(users.length).to eq 20
      expect(users[0]).to eq(
        User::Models::Profile.joins(:account).find_by(account: { username: 'billy_00' })
      )
      expect(users[19]).to eq(
        User::Models::Profile.joins(:account).find_by(account: { username: 'billy_19' })
      )
    end

    it 'should return the second page when requested' do
      users = described_class.call(query: 'username:billy', page: 2, per_page: 20).outputs.items
      expect(users.length).to eq 20
      expect(users[0]).to eq(
        User::Models::Profile.joins(:account).find_by(account: { username: 'billy_20' })
      )
      expect(users[19]).to eq(
        User::Models::Profile.joins(:account).find_by(account: { username: 'billy_39' })
      )
    end

    it 'should return the incomplete 3rd page when requested' do
      users = described_class.call(query: 'username:billy', page: 3, per_page: 20).outputs.items
      expect(users.length).to eq 6
      expect(users[5]).to eq(
        User::Models::Profile.joins(:account).find_by(account: { username: 'billy_45' })
      )
    end
  end

  context 'sorting' do
    let!(:bob_brown) do
      FactoryBot.create :user_profile, first_name: 'Bob', last_name: 'Brown', username: 'foo_bb'
    end
    let!(:bob_jones) do
      FactoryBot.create :user_profile, first_name: 'Bob', last_name: 'Jones', username: 'foo_bj'
    end
    let!(:tim_jones) do
      FactoryBot.create :user_profile, first_name: 'Tim', last_name: 'Jones', username: 'foo_tj'
    end

    it 'should allow sort by multiple fields DESC' do
      users = described_class.call(
        query: 'username:foo', order_by: 'first_name, last_name DESC'
      ).outputs.items
      expect(users).to eq [bob_jones, bob_brown, tim_jones]
    end

    it 'should allow sort by multiple fields ASC' do
      users = described_class.call(
        query: 'username:foo', order_by: 'first_name, last_name ASC'
      ).outputs.items
      expect(users).to eq [bob_brown, bob_jones, tim_jones]
    end
  end
end
