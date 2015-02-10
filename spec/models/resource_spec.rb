require 'rails_helper'

RSpec.describe Resource, :type => :model do
  subject { FactoryGirl.create :resource }

  it { is_expected.to have_one(:page).dependent(:destroy) }
  it { is_expected.to have_one(:exercise).dependent(:destroy) }
  it { is_expected.to have_one(:interactive).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:url) }

  it { is_expected.to validate_uniqueness_of(:url) }

  xit 'returns cached content if available' do
  end

  xit 'retrieves and caches content if not cached or expired' do
  end
end
