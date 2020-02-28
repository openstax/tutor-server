require 'rails_helper'

RSpec.describe GetExercises, type: :routine do
  let(:page)       { FactoryBot.create :content_page }
  let(:book)       { page.book }
  let(:ecosystem)  { book.ecosystem }
  let!(:exercises) { 5.times.map { FactoryBot.create :content_exercise, page: page } }

  before(:each)    { Content::Routines::PopulateExercisePools[book: book] }

  it 'can query by exercise ids' do
    ids = [exercises[0].id.to_s]
    result = described_class[ecosystem: ecosystem, exercise_ids: ids]
    expect(result.items.map(&:id)).to include ids.first
  end
end
