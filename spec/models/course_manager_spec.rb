require 'rails_helper'

RSpec.describe CourseManager, :type => :model do
  it { is_expected.to belong_to(:course) }
  it { is_expected.to belong_to(:user) }

  it { is_expected.to have_many(:taskings).dependent(:destroy) }
  it { is_expected.to have_many(:tasking_plans).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:course) }
  it { is_expected.to validate_presence_of(:user) }

  it 'requires a unique user for each course' do
    cm = FactoryGirl.create :course_manager
    expect(cm).to be_valid

    expect(FactoryGirl.build :course_manager,
                             course: cm.course, user: cm.user).not_to be_valid
  end
end
