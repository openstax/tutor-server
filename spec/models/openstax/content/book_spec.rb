require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Content::Book, type: :external, vcr: VCR_OPTS do
  let(:archive_version) { MINI_ECOSYSTEM_OPENSTAX_ARCHIVE_VERSION }
  let(:book_uuid)       { MINI_ECOSYSTEM_OPENSTAX_BOOK_HASH[:id] }
  let(:book_version)    { MINI_ECOSYSTEM_OPENSTAX_BOOK_HASH[:version] }

  let(:content_secrets)   { Rails.application.secrets.openstax[:content] }
  let(:expected_book_url) do
    "https://#{content_secrets[:domain]}/#{content_secrets[:archive_path]
    }/#{archive_version}/contents/#{book_uuid}@#{book_version}.json"
  end

  it "provides info about the book with the given id" do
    expect(MINI_ECOSYSTEM_OPENSTAX_BOOK.archive_version).to eq archive_version
    expect(MINI_ECOSYSTEM_OPENSTAX_BOOK.uuid).to eq book_uuid
    expect(MINI_ECOSYSTEM_OPENSTAX_BOOK.version).to eq book_version
    expect(MINI_ECOSYSTEM_OPENSTAX_BOOK.hash).not_to be_blank
    expect(MINI_ECOSYSTEM_OPENSTAX_BOOK.url).to eq expected_book_url
    expect(MINI_ECOSYSTEM_OPENSTAX_BOOK.title).to be_a(String)
    expect(MINI_ECOSYSTEM_OPENSTAX_BOOK.tree).not_to be_nil
    expect(MINI_ECOSYSTEM_OPENSTAX_BOOK.root_book_part).to be_a OpenStax::Content::BookPart
  end
end
