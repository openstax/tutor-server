require 'rails_helper'

RSpec.describe Tasks::Models::TaskPlan, :type => :model do
  it { is_expected.to belong_to(:assistant) }
  it { is_expected.to belong_to(:owner) }

  it { is_expected.to have_many(:tasking_plans).dependent(:destroy) }
  it { is_expected.to have_many(:tasks).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:owner) }
  it { is_expected.to validate_presence_of(:assistant) }
end
