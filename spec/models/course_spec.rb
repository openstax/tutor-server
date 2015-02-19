require 'rails_helper'

RSpec.describe Course, :type => :model do
  it { is_expected.to have_many(:sections).dependent(:destroy) }
  it { is_expected.to have_many(:educators).dependent(:destroy) }
  it { is_expected.to have_many(:students).dependent(:destroy) }
  it { is_expected.to have_many(:tasking_plans).dependent(:destroy) }
  it { is_expected.to have_many(:task_plans).dependent(:destroy) }
  it { is_expected.to have_many(:course_assistants).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:school) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:short_name) }
  it { is_expected.to validate_presence_of(:time_zone) }
  it { is_expected.to validate_inclusion_of(:time_zone).in_array(
    ActiveSupport::TimeZone.all.map(&:to_s)
  ) }
end

