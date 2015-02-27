require 'rails_helper'

RSpec.describe Content::Page, type: :model do
  subject { FactoryGirl.create :content_page }

  it { is_expected.to belong_to(:book) }
  it { is_expected.to belong_to(:book_part) }
  it { is_expected.to validate_presence_of(:title) }
end
