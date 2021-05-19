require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Content::Models::Page, type: :model, vcr: VCR_OPTS do
  let(:book)                do
    FactoryBot.create :content_book, archive_version: MINI_ECOSYSTEM_OPENSTAX_ARCHIVE_VERSION
  end
  subject(:page)            { FactoryBot.create :content_page, book: book }
  let(:same_book_page)      { FactoryBot.create :content_page, book: book }

  let(:different_book)      do
    FactoryBot.create :content_book, uuid: MINI_ECOSYSTEM_OPENSTAX_BOOK_HASH[:id]
  end
  let(:different_book_page) do
    FactoryBot.create :content_page, book: different_book,
                                     uuid: MINI_ECOSYSTEM_OPENSTAX_PAGE_HASHES.first[:id]
  end

  it { is_expected.to belong_to(:book) }

  it { is_expected.to validate_presence_of(:title) }

  it 'can resolve urls for links' do
    expect(page.resolve_link('http://www.example.com')).to eq 'https://www.example.com'

    expect(page.resolve_link('#Fig1_1')).to eq '#Fig1_1'

    expect(
      page.resolve_link("./#{page.book.uuid}@#{page.book.version}:#{page.uuid}.xhtml#Fig1_1")
    ).to eq '#Fig1_1'

    expect(
      page.resolve_link(
        "./#{page.book.uuid}@#{page.book.version}:#{same_book_page.uuid}.xhtml#Fig1_1"
      )
    ).to eq "#{same_book_page.reference_view_url}#Fig1_1"

    expect(
      page.resolve_link("./#{different_book.uuid}:#{different_book_page.uuid}.xhtml#Fig1_1")
    ).to eq(
      "https://#{Rails.application.secrets.openstax[:content][:domain]
      }/books/college-physics-courseware/pages/4-2-newtons-first-law-of-motion-inertia#Fig1_1"
    )

    expect(
      page.resolve_link('../resources/image')
    ).to eq OpenStax::Content::Archive.new(page.book.archive_version).url_for('../resources/image')
  end

  it 'can cache fragments and snap labs' do
  end
end
