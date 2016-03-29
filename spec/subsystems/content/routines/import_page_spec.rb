require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::ImportPage, type: :routine, speed: :slow, vcr: VCR_OPTS do

  let!(:chapter) { FactoryGirl.create :content_chapter }

  context 'tutor page' do
    let!(:cnx_page)  { OpenStax::Cnx::V1::Page.new(
      id: '95e61258-2faf-41d4-af92-f62e1414175a', title: 'Force'
    ) }
    let!(:book_location) { [4, 1] }

    it 'creates a new Page' do
      result = nil
      expect {
        result = import_page
      }.to change{ Content::Models::Page.count }.by(1)
      expect(result.errors).to be_empty

      expect(result.outputs[:page]).to be_persisted

      uuid = cnx_page.uuid
      version = cnx_page.version
      expect(result.outputs[:page].uuid).to eq uuid
      expect(result.outputs[:page].version).to eq version
      expect(result.outputs[:page].book_location).to eq book_location
    end

    it 'converts relative links into absolute links' do
      page = import_page.outputs[:page]
      doc = Nokogiri::HTML(page.content)

      doc.css('[src]').each do |tag|
        uri = URI.parse(URI.escape(tag.attributes['src'].value))
        expect(uri.absolute?).to eq true
      end
    end

    it 'finds LO tags in the content' do
      expected_page_tags = ['cnxmod:95e61258-2faf-41d4-af92-f62e1414175a',
                            'k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02',
                            'teks-112-39-c-4c', 'teks-112-39-c-4e']

      result = nil
      expect {
        result = import_page
      }.to change{ Content::Models::Tag.lo.count }.by(2)

      tags = Content::Models::Tag.lo.order(:id).to_a
      expect(tags[-2].value).to eq 'k12phys-ch04-s01-lo01'
      expect(tags[-1].value).to eq 'k12phys-ch04-s01-lo02'

      routine_tags = result.outputs[:tags]
      routine_tags_value_set = Set.new routine_tags.collect(&:value)
      expect(routine_tags_value_set).to eq Set.new(expected_page_tags)

      routine_tags_set = Set.new routine_tags
      page_tags_set = Set.new Content::Models::Page.last.page_tags.collect(&:tag)
      expect(routine_tags_set).to eq page_tags_set
    end

    it 'creates tags from ost-standard-defs' do
      result = import_page
      tag = Content::Models::Tag.find_by(value: 'teks-112-39-c-4c')
      expect(tag.name).to eq '(4C)'
      expect(tag.description).to eq 'analyze and describe accelerated motion in two dimensions using equations, including projectile and circular examples'
    end

    it 'gets exercises with LO tags from the content' do
      result = nil
      expect {
        result = import_page
      }.to change{ Content::Models::Exercise.count }.by(32)
    end
  end

  context 'cc page' do
    let!(:cnx_page)  { OpenStax::Cnx::V1::Page.new(
      id: '6a0568d8-23d7-439b-9a01-16e4e73886b3', title: 'The Science of Biology'
    ) }
    let!(:book_location) { [1, 1] }

    it 'creates a new Page' do
      result = nil
      expect {
        result = import_page(archive_url: 'https://archive.cnx.org/contents/')
      }.to change{ Content::Models::Page.count }.by(1)
      expect(result.errors).to be_empty

      expect(result.outputs[:page]).to be_persisted

      uuid = cnx_page.uuid
      version = cnx_page.version
      expect(result.outputs[:page].uuid).to eq uuid
      expect(result.outputs[:page].version).to eq version
      expect(result.outputs[:page].book_location).to eq book_location
    end

    it 'converts relative links into absolute links' do
      page = import_page(archive_url: 'https://archive.cnx.org/contents/').outputs[:page]
      doc = Nokogiri::HTML(page.content)

      doc.css('[src]').each do |tag|
        uri = URI.parse(URI.escape(tag.attributes['src'].value))
        expect(uri.absolute?).to eq true
      end
    end

    it 'finds cnxmod tags in the content' do
      expected_page_tag = 'cnxmod:6a0568d8-23d7-439b-9a01-16e4e73886b3'

      result = nil
      expect {
        result = import_page(archive_url: 'https://archive.cnx.org/contents/')
      }.to change{ Content::Models::Tag.cnxmod.count }.by(1)

      tag = Content::Models::Tag.cnxmod.order(:created_at).last
      expect(tag.value).to eq expected_page_tag

      routine_tags = result.outputs[:tags]
      expect(routine_tags.map(&:value)).to eq [expected_page_tag]

      page_tag_values = Content::Models::Page.order(:created_at).last.page_tags
                                                                     .collect{|pt| pt.tag.value}
      expect(page_tag_values).to include(expected_page_tag)
    end

    it 'gets exercises with the page\'s cnxmod tag and assigns page LO\'s from them' do
      result = nil
      expect {
        result = import_page(archive_url: 'https://archive.cnx.org/contents/')
      }.to change{ Content::Models::Exercise.count }.by(26)

      exercises = Content::Models::Exercise.order(:created_at).last(26)

      exercise_los_set = Set.new exercises.flat_map(&:los)
      page_tags_set = Set.new(
        Content::Models::Page.order(:created_at).last.page_tags.collect(&:tag)
      )
      expect(exercise_los_set).to be_subset(page_tags_set)
    end
  end

  def import_page(archive_url: OpenStax::Cnx::V1.archive_url_base)
    OpenStax::Cnx::V1.with_archive_url(archive_url) do
      Content::Routines::ImportPage.call(cnx_page: cnx_page,
                                         chapter: chapter,
                                         book_location: book_location)
    end
  end

end
