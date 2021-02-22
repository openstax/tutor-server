require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::ImportPage, type: :routine, vcr: VCR_OPTS do
  let(:book) { FactoryBot.create :content_book }
  let(:parent_book_part_uuid) { SecureRandom.uuid }

  context 'tutor page' do
    let(:cnx_page)  do
      OpenStax::Cnx::V1::Page.new(id: 'de43ae15-d1fa-4265-98f6-9820ff31a270', title: 'Development of Force Concept')
    end
    let(:archive_url)           { OpenStax::Cnx::V1.archive_url_base }
    let(:book_indices)          { [4, 1] }

    it 'creates a new Page' do
      result = nil
      expect do
        result = import_page
      end.to change { Content::Models::Page.count }.by(1)
      expect(result.errors).to be_empty

      expect(result.outputs.page).to be_persisted

      uuid = cnx_page.uuid
      version = cnx_page.version
      expect(result.outputs.page.uuid).to eq uuid
      expect(result.outputs.page.version).to eq version
      expect(result.outputs.page.book_indices).to eq book_indices
    end

    it 'converts relative links into absolute links' do
      page = import_page.outputs.page
      doc = Nokogiri::HTML(page.content)

      doc.css('[src]').each do |tag|
        uri = URI.parse(Addressable::URI.escape(tag.attributes['src'].value))
        expect(uri.absolute?).to eq true
      end
    end

    it 'finds LO tags in the content' do
      expected_page_los_set = Set[]
      expected_exercise_los_set = Set['lo:stax-phys:4-1-1']
      expected_routine_tags_set = Set['context-cnxmod:de43ae15-d1fa-4265-98f6-9820ff31a270']

      result = nil
      expect { result = import_page }.to change { Content::Models::Tag.lo.count }.by(1)

      los_set = Set.new Content::Models::Tag.lo.order(:created_at).last(1).map(&:value)
      expect(los_set).to eq(expected_page_los_set + expected_exercise_los_set)

      routine_tags_set = Set.new result.outputs.page.tags.map(&:value)
      expect(routine_tags_set).to eq expected_routine_tags_set

      page_tags_set = Set.new Content::Models::Page.last.page_tags.map { |pt| pt.tag.value }
      expect(page_tags_set).to eq expected_routine_tags_set + expected_page_los_set
    end

    it 'gets exercises with LO tags from the content' do
      result = nil
      expect do
        result = import_page
      end.to change { Content::Models::Exercise.count }.by(2)
    end
  end

  def import_page
    OpenStax::Cnx::V1.with_archive_url(archive_url) do
      Content::Routines::ImportPage.call(
        cnx_page: cnx_page,
        book: book,
        book_indices: book_indices,
        parent_book_part_uuid: parent_book_part_uuid
      )
    end
  end
end
