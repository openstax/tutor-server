require 'rails_helper'

RSpec.describe Content::Models::Chapter, type: :model do
  subject(:chapter) { FactoryBot.create :content_chapter }

  it { is_expected.to belong_to(:book) }

  it { is_expected.to have_many(:pages).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:book_location) }
end
