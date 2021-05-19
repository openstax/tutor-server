require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::ImportPage, type: :routine, vcr: VCR_OPTS do
  let(:book) { FactoryBot.create :content_book }
  let(:parent_book_part_uuid) { SecureRandom.uuid }

  let(:ox_page) do
    OpenStax::Content::Page.new(
      book: MINI_ECOSYSTEM_OPENSTAX_BOOK,
      hash: {
        id: '7344986b-3079-4db2-92b9-78e0644c8610',
        title: 'Development of Force Concept'
      }.deep_stringify_keys
    )
  end
  let(:book_indices) { [4, 1] }

  it 'creates a new Page' do
    result = nil
    expect do
      result = import_page
    end.to change { Content::Models::Page.count }.by(1)
    expect(result.errors).to be_empty

    expect(result.outputs.page).to be_persisted

    uuid = ox_page.uuid
    expect(result.outputs.page.uuid).to eq uuid
    expect(result.outputs.page.book_indices).to eq book_indices
  end

  it 'finds LO tags in the content' do
    expected_page_tags_set = Set['context-cnxmod:7344986b-3079-4db2-92b9-78e0644c8610']
    expected_los_set = Set[
      'lo:stax-phys:4-1-1', 'k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02'
    ]

    result = nil
    expect { result = import_page }.to change { Content::Models::Tag.lo.count }.by(3)

    routine_tags_set = Set.new result.outputs.page.tags.map(&:value)
    expect(routine_tags_set).to eq expected_page_tags_set

    page = Content::Models::Page.last
    page_tags_set = Set.new page.page_tags.map { |pt| pt.tag.value }
    expect(page_tags_set).to eq expected_page_tags_set

    los_set = Set.new page.exercises.flat_map(&:tags).filter(&:lo?).map(&:value)
    expect(los_set).to eq expected_los_set
  end

  it 'gets exercises with LO tags from the content' do
    result = nil
    expect do
      result = import_page
    end.to change { Content::Models::Exercise.count }.by(8)
  end

  def import_page
    Content::Routines::ImportPage.call(
      ox_page: ox_page,
      book: book,
      book_indices: book_indices,
      parent_book_part_uuid: parent_book_part_uuid
    )
  end
end
