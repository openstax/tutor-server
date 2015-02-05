require 'rails_helper'

RSpec.describe BookInteractive, :type => :model do
  subject { FactoryGirl.create :book_interactive }

  it { is_expected.to belong_to(:book) }
  it { is_expected.to belong_to(:interactive) }

  it { is_expected.to validate_presence_of(:book) }
  it { is_expected.to validate_presence_of(:interactive) }

  it { is_expected.to validate_uniqueness_of(:interactive).scoped_to(:book_id) }
end
