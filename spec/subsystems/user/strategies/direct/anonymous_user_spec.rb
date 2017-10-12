require 'rails_helper'

RSpec.describe User::Strategies::Direct::AnonymousUser, type: :strategy do
  subject(:anon) { described_class.new(::User::Models::AnonymousProfile.instance) }

  it 'uses an anonymous account' do
    expect(anon.account).to be_kind_of(OpenStax::Accounts::AnonymousAccount)
  end

  it 'is anonymous' do
    expect(anon).to be_is_anonymous
  end

  it 'is human' do
    expect(anon.is_human?).to be_truthy
  end

  it 'is not an application' do
    expect(anon.is_application?).to be_falsy
  end
end
