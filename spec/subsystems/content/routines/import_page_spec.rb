require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::ImportPage, type: :routine, vcr: VCR_OPTS do
  let(:book) { FactoryBot.create :content_book }
  let(:parent_book_part_uuid) { SecureRandom.uuid }

  context 'tutor page' do
    let(:cnx_page)  do
      OpenStax::Cnx::V1::Page.new(id: '95e61258-2faf-41d4-af92-f62e1414175a', title: 'Force')
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
        uri = URI.parse(URI.escape(tag.attributes['src'].value))
        expect(uri.absolute?).to eq true
      end
    end

    it 'finds LO tags in the content' do
      expected_page_los_set = Set['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02']
      expected_exercise_los_set = Set['lo:stax-k12phys:4-1-1', 'lo:stax-k12phys:4-1-2']
      expected_routine_tags_set = Set['context-cnxmod:95e61258-2faf-41d4-af92-f62e1414175a',
                                      'k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02',
                                      'teks-112-39-c-4c', 'teks-112-39-c-4e']

      result = nil
      expect { result = import_page }.to change { Content::Models::Tag.lo.count }.by(4)

      los_set = Set.new Content::Models::Tag.lo.order(:created_at).last(4).map(&:value)
      expect(los_set).to eq(expected_page_los_set + expected_exercise_los_set)

      routine_tags_set = Set.new result.outputs.page.tags.map(&:value)
      expect(routine_tags_set).to eq expected_routine_tags_set

      page_tags_set = Set.new Content::Models::Page.last.page_tags.map { |pt| pt.tag.value }
      expect(page_tags_set).to eq expected_routine_tags_set + expected_page_los_set
    end

    it 'creates tags from ost-standard-defs' do
      result = import_page
      tag = Content::Models::Tag.find_by(value: 'teks-112-39-c-4c')
      expect(tag.name).to eq '(4C)'
      expect(tag.description).to eq 'analyze and describe accelerated motion in two dimensions using equations, including projectile and circular examples'
    end

    it 'gets exercises with LO tags from the content' do
      result = nil
      expect do
        result = import_page
      end.to change { Content::Models::Exercise.count }.by(32)
    end
  end

  context 'cc page' do
    let(:cnx_page)  do
      OpenStax::Cnx::V1::Page.new(
        id: '6a0568d8-23d7-439b-9a01-16e4e73886b3', title: 'The Science of Biology'
      )
    end
    let(:archive_url)  { 'https://archive.cnx.org/contents/' }
    let(:book_indices) { [1, 1] }

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
        uri = URI.parse(URI.escape(tag.attributes['src'].value))
        expect(uri.absolute?).to eq true
      end
    end

    it 'finds cnxmod tags in the content' do
      expected_page_tag = 'context-cnxmod:6a0568d8-23d7-439b-9a01-16e4e73886b3'

      result = nil
      expect do
        result = import_page
      end.to change { Content::Models::Tag.cnxmod.count }.by(1)

      tag = Content::Models::Tag.cnxmod.order(:created_at).last
      expect(tag.value).to eq expected_page_tag

      routine_tags = result.outputs.page.tags
      expect(routine_tags.map(&:value)).to eq [expected_page_tag]

      page_tag_values = Content::Models::Page.order(:created_at).last.page_tags
                                                                     .map{|pt| pt.tag.value}
      expect(page_tag_values).to include(expected_page_tag)
    end

    it 'gets exercises with the page\'s cnxmod tag' do
      result = nil
      expect do
        result = import_page
      end.to change { Content::Models::Exercise.count }.by(26)

      exercises = Content::Models::Exercise.order(:created_at).last(26)
      page = Content::Models::Page.order(:created_at).last

      expect(page.los).to be_empty
      page_cnxmods = page.cnxmods
      expect(page_cnxmods).not_to be_empty

      exercises.each { |exercise| expect(exercise.cnxmods & page_cnxmods).not_to be_empty }
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
