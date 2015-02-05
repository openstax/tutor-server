require 'rails_helper'

RSpec.describe BookVideo, :type => :model do
  subject { FactoryGirl.create :book_video }

  it { is_expected.to belong_to(:book) }
  it { is_expected.to belong_to(:video) }

  it { is_expected.to validate_presence_of(:book) }
  it { is_expected.to validate_presence_of(:video) }

  it { is_expected.to validate_uniqueness_of(:video).scoped_to(:book_id) }
end
