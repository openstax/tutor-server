require 'rails_helper'

RSpec.describe Klass, :type => :model do
  it { is_expected.to belong_to(:course) }
  it { is_expected.to have_many(:sections).dependent(:destroy) }
  it { is_expected.to have_many(:educators).dependent(:destroy) }
  it { is_expected.to have_many(:students).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:course) }
  it { is_expected.to validate_inclusion_of(:time_zone).in_array(ActiveSupport::TimeZone.all.map(&:to_s)).allow_nil }
end

