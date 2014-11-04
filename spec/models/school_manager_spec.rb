require 'rails_helper'

RSpec.describe SchoolManager, :type => :model do
  it { is_expected.to belong_to(:school) }
  it { is_expected.to belong_to(:user) }

  it { is_expected.to have_many(:taskings).dependent(:destroy) }
  it { is_expected.to have_many(:tasking_plans).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:school) }
  it { is_expected.to validate_presence_of(:user) }

  it 'requires a unique user for each school' do
    sm = FactoryGirl.create :school_manager
    expect(sm).to be_valid

    expect(FactoryGirl.build :school_manager,
                             school: sm.school, user: sm.user).not_to be_valid
  end
end
