require 'rails_helper'

RSpec.describe ActsAsResource do
  context 'content_exercise' do
    subject(:exercise) { FactoryGirl.create :content_exercise }

    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_uniqueness_of(:url) }
  end

  context 'content_page' do
    subject(:page) { FactoryGirl.create :content_page }

    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.not_to validate_uniqueness_of(:url) }
  end

  context 'book' do
    subject(:book) { FactoryGirl.create :content_book }

    it { is_expected.not_to validate_presence_of(:url) }
    it { is_expected.to validate_uniqueness_of(:url).allow_nil }
  end
end
