require 'rails_helper'

RSpec.describe Book, :type => :model do
  subject { FactoryGirl.create :book }

  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:edition) }

  it { is_expected.to validate_uniqueness_of(:url) }
  it { is_expected.to validate_uniqueness_of(:edition).scoped_to(:title) }
end
