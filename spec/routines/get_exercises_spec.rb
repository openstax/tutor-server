require 'rails_helper'

RSpec.describe GetExercises, type: :routine do
  let(:page)       { FactoryBot.create :content_page }
  let(:book)       { page.book }
  let(:ecosystem)  { book.ecosystem }
  let!(:exercises) { 10.times.map { FactoryBot.create :content_exercise, page: page } }
  let!(:versions)  {
    2.times.map.with_index {|i| FactoryBot.create :content_exercise, page: page, number: 1, version: i }
  }

  before(:each)    { Content::Routines::PopulateExercisePools[book: book] }

  it 'can query by exercise ids' do
    ids = exercises[2..7].map(&:id).map(&:to_s)
    result = described_class[ecosystem: ecosystem, exercise_ids: ids]
    expect(Set.new result.items.map(&:id)).to eq Set.new(ids)
  end

  it 'returns the latest version of the same number' do
    result = described_class[ecosystem: ecosystem, exercise_ids: versions.map(&:id)]
    expect(result.items.map(&:id)).to eq([versions.last.id.to_s])
  end
end
