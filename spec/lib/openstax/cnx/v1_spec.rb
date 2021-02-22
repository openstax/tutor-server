require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1, type: :external, vcr: VCR_OPTS do
  let(:cnx_collection_id) { PopulateMiniEcosystem.cnx_book_hash[:id] }
  let(:cnx_module_id)     { PopulateMiniEcosystem.cnx_page_hashes.first[:id] }

  it "can generate url's for resources in the cnx archive" do
    expect(OpenStax::Cnx::V1.archive_url_for('module_id@version')).to(
      eq('https://archive.cnx.org/contents/module_id@version'))

    expect(OpenStax::Cnx::V1.archive_url_for('/resources/image.jpg')).to(
      eq('https://archive.cnx.org/resources/image.jpg'))

    OpenStax::Cnx::V1.with_archive_url('https://archive.cnx.org/contents') do
      expect(OpenStax::Cnx::V1.archive_url_for('module_id@version')).to(
        eq('https://archive.cnx.org/contents/module_id@version'))
    end

    OpenStax::Cnx::V1.with_archive_url('https://archive.cnx.org/contents/') do
      expect(OpenStax::Cnx::V1.archive_url_for('module_id@version')).to(
        eq('https://archive.cnx.org/contents/module_id@version'))
    end
  end

  it "can fetch collections and modules from CNX" do
    collection_hash = OpenStax::Cnx::V1.fetch(OpenStax::Cnx::V1.archive_url_for(cnx_collection_id))
    module_hash = OpenStax::Cnx::V1.fetch(OpenStax::Cnx::V1.archive_url_for(cnx_module_id))

    expect(collection_hash).to be_a Hash
    expect(collection_hash).not_to be_empty

    expect(module_hash).to be_a Hash
    expect(module_hash).not_to be_empty
  end

  it "can instantiate a Book from an id" do
    book = OpenStax::Cnx::V1.book(id: cnx_collection_id)

    expect(book).to be_a OpenStax::Cnx::V1::Book
  end

  it 'rescues OpenURI::HTTPError for intended URL clarification' do
    expect {
      OpenStax::Cnx::V1.fetch(OpenStax::Cnx::V1.archive_url_for('no-exist'))
    }.to raise_error(
      OpenStax::HTTPError,
      "404 Not Found for URL https://archive.cnx.org/contents/no-exist"
    )
  end
end
