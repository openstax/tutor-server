require 'rails_helper'

RSpec.describe GetExercises, type: :routine do
  let(:content_page) { FactoryBot.create :content_page }
  let(:page)      {
    strategy = ::Content::Strategies::Direct::Page.new(content_page)
    ::Content::Page.new(strategy: strategy)

  }
  let(:ecosystem) { page.chapter.book.ecosystem }
  let!(:exercises) { 5.times.map{ FactoryBot.create :content_exercise, page: content_page } }

  before(:each) {
    Content::Routines::PopulateExercisePools[book: content_page.chapter.book]
  }

  it 'can query by exercise ids' do
    ids = [exercises[0].id.to_s]
    result = described_class[ecosystem: ecosystem, exercise_ids: ids]
    expect(result.items.map(&:id)).to include ids.first
  end

end
