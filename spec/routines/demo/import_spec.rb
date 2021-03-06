require 'rails_helper'
require 'vcr_helper'

RSpec.describe Demo::Import, type: :routine, vcr: VCR_OPTS do
  before { skip("disabled since it imports entire book, which we only want to run manually") }

  let(:config_base_dir) { File.join Rails.root, 'spec', 'fixtures', 'demo' }
  let(:import_config)   do
    {
      import: Api::V1::Demo::Import::Representer.new(Demo::Mash.new).from_hash(
        YAML.load_file File.join(config_base_dir, 'import', 'review', 'apush.yml')
      ).deep_symbolize_keys
    }
  end
  let(:result)          { described_class.call import_config }

  it 'imports the demo book' do
    catalog_offering = nil
    expect do
      expect(result.errors).to be_empty
      catalog_offering = result.outputs.catalog_offering
    end.to  change { Content::Models::Ecosystem.count }.by(1)
       .and change { Content::Models::Book.count }.by(1)
       .and change { Content::Models::Page.count }.by(5)
       .and change { Content::Models::Exercise.count }.by(30)
       .and change { Catalog::Models::Offering.count }.by(1)

    expect(catalog_offering.title).to eq 'AP US History'
    expect(catalog_offering.description).to eq 'AP US History'
    expect(catalog_offering.default_course_name).to eq 'AP US History'
    expect(catalog_offering.salesforce_book_name).to eq 'AP US History'
    expect(catalog_offering.appearance_code).to eq 'ap_us_history'

    ecosystem = catalog_offering.ecosystem
    expect(ecosystem.title).to include 'APUSH'
    expect(ecosystem.title).to include '36004586-651c-4ded-af87-203aca22d946'

    book = ecosystem.books.first
    expect(book.archive_version).to eq '20210514.171726'
    expect(book.title).to eq 'APUSH'
    expect(book.uuid).to eq '36004586-651c-4ded-af87-203aca22d946'
    expect(book.version).to eq '14.3'
    expect(book.url).to include(
      'https://openstax.org/apps/archive/20210514.171726/contents/36004586-651c-4ded-af87-203aca22d946@14.3.json'
    )

    chapter = book.chapters.first
    expect(chapter.title).to match 'Chapter 1'
    expect(chapter.book_location).to eq [1]

    pages = chapter.pages
    expect(pages.map(&:title)).to match([
      'Introduction',
      'Douglass struggles toward literacy',
      "Douglass struggles against slavery’s injustice",
      'Douglass promotes dignity',
      'Confrontation seeking righteousness'
    ].map{ |title| a_string_matching(title)})
    expect(pages.map(&:book_location)).to eq [[], [1, 1], [1, 2], [1, 3], [1, 4]]
  end
end
