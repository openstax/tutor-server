require 'rails_helper'
require 'vcr_helper'

RSpec.describe ImportEcosystemManifest, type: :routine do

  context 'with book' do
    before(:all) do
      DatabaseCleaner.start

      VCR.insert_cassette("ImportEcosystemManifest/with_book", VCR_OPTS)

      @ecosystem = FetchAndImportBookAndCreateEcosystem[
        book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
      ]
    end

    after(:all) do
      VCR.eject_cassette(VCR_OPTS)

      DatabaseCleaner.clean
    end

    it 'can import an ecosystem from a manifest' do
      expected_cnx_ids = Set.new @ecosystem.books.collect(&:cnx_id)

      manifest = @ecosystem.manifest
      Content::Models::Ecosystem.destroy_all

      expect{ @new_ecosystem = described_class.call(manifest: manifest) }.to(
        change{ Content::Models::Ecosystem.count }.by(1)
      )

      expect(Set.new @new_ecosystem.books.collect(&:cnx_id)).to eq expected_cnx_ids
    end
  end

end
