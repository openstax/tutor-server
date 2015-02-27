require 'rails_helper'

RSpec.describe Content::BookPart, :type => :model do
  subject { FactoryGirl.create :content_book_part }

  it { is_expected.to belong_to(:book) }
  it { is_expected.to belong_to(:parent_book_part) }
  it { is_expected.to have_many(:child_book_parts).dependent(:destroy) }
  it { is_expected.to have_many(:pages).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:title) }
end
