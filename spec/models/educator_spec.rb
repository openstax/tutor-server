require 'rails_helper'

RSpec.describe Educator, :type => :model do
  it { is_expected.to belong_to(:klass) }
  it { is_expected.to belong_to(:user) }

  it { is_expected.to have_many(:taskings).dependent(:destroy) }
  it { is_expected.to have_many(:tasking_plans).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:klass) }
  it { is_expected.to validate_presence_of(:user) }

  it 'requires a unique user for each klass' do
    e = FactoryGirl.create :educator
    expect(e).to be_valid

    expect(FactoryGirl.build :educator,
                             klass: e.klass, user: e.user).not_to be_valid
  end
end
