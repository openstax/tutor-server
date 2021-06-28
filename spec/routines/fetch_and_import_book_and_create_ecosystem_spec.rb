require 'rails_helper'
require 'vcr_helper'

RSpec.describe FetchAndImportBookAndCreateEcosystem, type: :routine,
                                                     vcr: VCR_OPTS,
                                                     speed: :medium do
  before do
    expect(Content::UploadEcosystemManifestToValidator).to receive(:perform_later) do |manifest|
      expect(manifest).to be_a(String)
    end
  end

  let(:archive_version) { '0.1' }
  let(:book_uuid)       { '93e2b09d-261c-4007-a987-0b3062fe154b' }
  let(:book_version)    { '4.4' }
  let(:book_url)        do
    OpenStax::Content::Archive.new(archive_version).url_for("#{book_uuid}@#{book_version}")
  end
  let(:reading_processing_instructions) do
    YAML.load_file('config/reading_processing_instructions.yml')['hs-physics']
  end

  it 'imports books and exercises as ecosystems' do
    expect do
      described_class.call(
        archive_version: archive_version,
        book_uuid: book_uuid,
        book_version: book_version,
        reading_processing_instructions: reading_processing_instructions
      )
    end.to change { Content::Models::Ecosystem.count }.by(1)
  end

  it 'imports a book even if the book already exists' do
    FactoryBot.create(
      :content_book,
      title: 'Physics',
      url: book_url,
      version: book_version
    )

    expect do
      described_class.call(
        archive_version: archive_version,
        book_uuid: book_uuid,
        book_version: book_version,
        reading_processing_instructions: reading_processing_instructions
      )
    end.to change { Content::Models::Ecosystem.count }.by(1)
  end

  it 'imports a book with a different version' do
    FactoryBot.create(
      :content_book,
      title: 'Physics',
      url: book_url,
      version: book_version
    )

    expect do
      described_class.call(
        archive_version: archive_version,
        book_uuid: book_uuid,
        book_version: '4.3',
        reading_processing_instructions: reading_processing_instructions
      )
    end.to change { Content::Models::Ecosystem.count }.by(1)
  end
end
