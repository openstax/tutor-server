require 'rails_helper'

RSpec.describe Page, type: :model do
  subject { FactoryGirl.create :page }

  it { is_expected.to belong_to(:resource) }
  it { is_expected.to belong_to(:chapter) }

  it { is_expected.to validate_presence_of(:resource) }
  it { is_expected.to validate_presence_of(:chapter) }

  it { is_expected.to validate_uniqueness_of(:resource) }
end
