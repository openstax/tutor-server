require 'rails_helper'

RSpec.describe Settings::Notifications, type: :lib do

  after(:each) do
    Settings::Redis.store.del(Settings::Notifications::KEY)
  end

  it 'can store a message' do
    expect {
      Settings::Notifications.add('a test message')
    }.to_not raise_error
  end

  it 'reads raw json' do
    Settings::Notifications.add('a stored message')
    expect(Settings::Notifications.raw).to include('"message":"a stored message"')
  end

  it 'removes a single message' do
    Settings::Notifications.add('message one')
    two = Settings::Notifications.add('message two')
    Settings::Notifications.add('message three')
    expect(Settings::Notifications.count).to eq(3)
    Settings::Notifications.remove(two['id'])
    expect(Settings::Notifications.map{|n|n['message']}).to eq(
      ["message one", "message three"]
    )
  end

  it 'can iterate through messages' do
    1.upto(3){ | num | Settings::Notifications.add("message #{num}") }
    i = 0
    Settings::Notifications.each do | notice |
      expect(notice['message']).to eq("message #{i+=1}")
    end
  end

end
