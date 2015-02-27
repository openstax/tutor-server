require 'rails_helper'

RSpec.describe Content::Page, type: :model do
  subject { FactoryGirl.create :page }

  it { is_expected.to belong_to(:book) }

  it { is_expected.to validate_presence_of(:title) }
end
