require 'rails_helper'

RSpec.describe BookReading, :type => :model do
  subject { FactoryGirl.create :book_reading }

  it { is_expected.to belong_to(:book) }
  it { is_expected.to belong_to(:reading) }

  it { is_expected.to validate_presence_of(:book) }
  it { is_expected.to validate_presence_of(:reading) }

  it { is_expected.to validate_uniqueness_of(:reading).scoped_to(:book_id) }
end
