require 'rails_helper'

RSpec.describe PageInteractive, type: :model do
  subject { FactoryGirl.create :page_interactive }

  it { is_expected.to belong_to(:page) }
  it { is_expected.to belong_to(:interactive) }

  it { is_expected.to validate_presence_of(:page) }
  it { is_expected.to validate_presence_of(:interactive) }

  it {
    is_expected.to validate_uniqueness_of(:interactive).scoped_to(:page_id)
  }
end
