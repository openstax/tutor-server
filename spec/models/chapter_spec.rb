require 'rails_helper'

RSpec.describe Chapter, type: :model do
  subject { FactoryGirl.create :chapter }

  it { is_expected.to belong_to(:book) }

  it { is_expected.to validate_presence_of(:book) }
  it { is_expected.to validate_presence_of(:title) }

  it { is_expected.to validate_uniqueness_of(:title).scoped_to(:book_id) }
end
