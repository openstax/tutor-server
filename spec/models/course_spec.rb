require 'rails_helper'

RSpec.describe Course, :type => :model do
  subject { FactoryGirl.create :course }

  it { is_expected.to belong_to(:school) }

  it { is_expected.to have_many(:klasses).dependent(:destroy) }
  it { is_expected.to have_many(:course_managers).dependent(:destroy) }
  it { is_expected.to have_many(:tasking_plans).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:short_name) }
  it { is_expected.to validate_presence_of(:description) }

  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:school_id) }
  it { is_expected.to validate_uniqueness_of(:short_name).scoped_to(:school_id) }
end
