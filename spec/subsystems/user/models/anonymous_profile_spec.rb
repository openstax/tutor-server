require 'rails_helper'

RSpec.describe User::Models::AnonymousProfile, type: :model do
  subject(:anon) { described_class.instance }

  it 'uses an anonymous account' do
    expect(anon.account).to be_kind_of(OpenStax::Accounts::AnonymousAccount)
  end

  it 'has no account id' do
    expect(anon.account_id).to be_nil
  end

  it 'has an unknown role' do
    expect(anon.role).to eq 'unknown_role'
  end

  it 'has no_faculty_info' do
    expect(anon.faculty_status).to eq 'no_faculty_info'
  end

  it 'has unknown_school_type' do
    expect(anon.school_type).to eq 'unknown_school_type'
  end

  it 'has unknown_school_location' do
    expect(anon.school_location).to eq 'unknown_school_location'
  end

  it 'cannot create courses' do
    expect(anon.can_create_courses?).to eq false
  end
end
