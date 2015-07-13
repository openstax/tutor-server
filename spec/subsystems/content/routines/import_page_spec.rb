require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::ImportPage, type: :routine, speed: :slow, vcr: VCR_OPTS do

  let!(:book_part) { FactoryGirl.create :content_book_part }
  let!(:cnx_page)  { OpenStax::Cnx::V1::Page.new(id: '95e61258-2faf-41d4-af92-f62e1414175a',
                                                 title: 'Force') }
  let!(:chapter_section) { [-1] }

  it 'creates a new Page' do
    result = nil
    expect {
      result = import_page
    }.to change{ Content::Models::Page.count }.by(1)
    expect(result.errors).to be_empty

    expect(result.outputs[:page]).to be_persisted

    uuid, version = cnx_page.id.split('@')
    expect(result.outputs[:page].uuid).to eq uuid
    expect(result.outputs[:page].version).to eq version
    expect(result.outputs[:page].chapter_section).to eq chapter_section
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
    result = nil
    expect {
      result = import_page
    }.to change{ Content::Models::Tag.lo.count }.by(2)

    tags = Content::Models::Tag.lo.order(:id).to_a
    expect(tags[-2].value).to eq 'k12phys-ch04-s01-lo01'
    expect(tags[-1].value).to eq 'k12phys-ch04-s01-lo02'

    tagged_tags = result.outputs[:tags]
    expect(tagged_tags).not_to be_empty
    expect(Set.new tagged_tags.collect{|t| t.value}).to(
      eq Set.new(Content::Models::Page.last.page_tags.collect{|pt| pt.tag.value})
    )
    expected_tagged_tags = ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02',
                            'teks-112-39-c-4c', 'teks-112-39-c-4e']
    expect(Set.new tagged_tags.collect{|t| t.value}).to eq Set.new(expected_tagged_tags)
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
    }.to change{ Content::Models::Exercise.count }.by(33)

    exercises = Content::Models::Exercise.all.order(:id).to_a
  end

  def import_page
    Content::Routines::ImportPage.call(cnx_page: cnx_page,
                                       book_part: book_part,
                                       chapter_section: chapter_section)
  end

end
