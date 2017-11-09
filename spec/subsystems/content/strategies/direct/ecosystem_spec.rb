require 'rails_helper'

RSpec.describe Content::Strategies::Direct::Ecosystem do
  let(:ecosystem_book) { FactoryBot.create(:content_book) }
  let(:ecosystem)      { ecosystem_book.ecosystem }
  let(:strategy)       { described_class.new(ecosystem) }

  it 'can generate a manifest' do
    manifest = strategy.manifest
    expect(manifest).to be_valid
    expect(manifest.title).to eq ecosystem.title
    manifest_book = manifest.books.first

    expect(manifest_book.archive_url).to eq ecosystem_book.archive_url
    expect(manifest_book.cnx_id).to eq ecosystem_book.cnx_id
    expect(manifest_book.reading_processing_instructions).not_to be_empty
    manifest_book.reading_processing_instructions.each do |processing_instruction|
      expect(processing_instruction).to be_a Hash
    end
    expect(manifest_book.exercise_ids).to eq ecosystem_book.exercises.map(&:uid)
  end
end
