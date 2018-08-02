require 'rails_helper'

RSpec.describe Content::Strategies::Direct::Ecosystem do
  let(:exercise)     do
    FactoryBot.create :content_exercise, nickname: 'Test', tags: [ 'test:true' ]
  end
  let(:book)         { exercise.page.chapter.book }
  let(:ecosystem)    { book.ecosystem }
  subject(:strategy) { described_class.new(ecosystem) }
  before             do
    exercise.tags = [ FactoryBot.create(:content_tag, value: 'test:true', ecosystem: ecosystem) ]
    exercise.save!
  end

  {
    exercises_by_ids: :id,
    exercises_by_nicknames: :nickname,
    exercises_with_tags: { tags: :value }
  }.each do |method, arg|
    it "can return #{method}" do
      value = case arg
      when Hash
        exercise.public_send(arg.keys.first).map(&arg.values.first)
      else
        exercise.public_send(arg)
      end
      expect(strategy.public_send(method, value)).to(
        eq [Content::Exercise.new(strategy: exercise.wrap)]
      )
    end
  end

  it 'can generate a manifest' do
    manifest = strategy.manifest
    expect(manifest).to be_valid
    expect(manifest.title).to eq ecosystem.title
    manifest_book = manifest.books.first

    expect(manifest_book.archive_url).to eq book.archive_url
    expect(manifest_book.cnx_id).to eq book.cnx_id
    expect(manifest_book.reading_processing_instructions).not_to be_empty
    manifest_book.reading_processing_instructions.each do |processing_instruction|
      expect(processing_instruction).to be_a Hash
    end
    expect(manifest_book.exercise_ids).to eq book.exercises.map(&:uid)
  end
end
