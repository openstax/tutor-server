require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Content::Archive, type: :external, vcr: VCR_OPTS do
  subject(:archive)       { described_class.new MINI_ECOSYSTEM_OPENSTAX_ARCHIVE_VERSION }
  let(:expected_base_url) do
    "https://openstax.org/apps/archive/#{MINI_ECOSYSTEM_OPENSTAX_ARCHIVE_VERSION}"
  end

  it 'can generate urls for collections' do
    [ '', '.xhtml', '.json' ].each do |extension|
      expect(archive.url_for("book-uuid@book-version#{extension}")).to(
        eq "#{expected_base_url}/contents/book-uuid@book-version.json"
      )
    end
  end

  it 'can generate urls for pages' do
    [ '', '.xhtml', '.json' ].each do |extension|
      expect(archive.url_for("book-uuid@book-version:page-uuid#{extension}")).to(
        eq "#{expected_base_url}/contents/book-uuid@book-version:page-uuid.json"
      )
    end
  end

  it 'can generate urls for resources' do
    expect(archive.url_for('../resources/image')).to(eq "#{expected_base_url}/resources/image")
  end

  it 'can fetch and parse collection JSON' do
    collection_hash = archive.json(
      "#{MINI_ECOSYSTEM_OPENSTAX_BOOK_HASH[:id]}@#{MINI_ECOSYSTEM_OPENSTAX_BOOK_HASH[:version]}"
    )

    expect(collection_hash).to be_a Hash
    expect(collection_hash).not_to be_empty
  end

  it 'can find book and page slugs' do
    book_id = MINI_ECOSYSTEM_OPENSTAX_BOOK_HASH[:id]
    expect(archive.slug book_id).to eq 'college-physics-courseware'

    page_id = MINI_ECOSYSTEM_OPENSTAX_PAGE_HASHES.first[:id]
    expect(archive.slug "#{book_id}:#{page_id}").to eq '4-2-newtons-first-law-of-motion-inertia'
  end
end
