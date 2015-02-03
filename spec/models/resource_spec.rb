require 'rails_helper'

RSpec.describe Resource, :type => :model do
  it { is_expected.to have_one(:reading).dependent(:destroy) }
  it { is_expected.to have_one(:exercise).dependent(:destroy) }
  it { is_expected.to have_one(:interactive).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:url) }

  it { is_expected.to validate_uniqueness_of(:url) }
end
