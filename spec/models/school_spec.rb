require 'rails_helper'

RSpec.describe School, :type => :model do
  it { is_expected.to have_many(:school_managers).dependent(:destroy) }
  it { is_expected.to have_many(:courses).dependent(:destroy) }
  it { is_expected.to have_many(:tasking_plans).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  it { is_expected.to validate_inclusion_of(:default_time_zone).in_array(ActiveSupport::TimeZone.all.map(&:to_s)).allow_nil }
end
