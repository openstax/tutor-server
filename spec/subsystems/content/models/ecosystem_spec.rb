require 'rails_helper'

RSpec.shared_examples 'ecosystem specs' do
  it 'can create a manifest hash' do
    expect(ecosystem.manifest_hash).to eq(
      {
        title: ecosystem.title,
        books: ecosystem.books.map(&:manifest_hash)
      }
    )
  end

  it 'has the correct title' do
    expect(ecosystem.title).to eq expected_title
  end
end

RSpec.describe Content::Models::Ecosystem, type: :model do
  subject(:ecosystem) { FactoryBot.create :content_ecosystem }

  it { is_expected.to have_many(:course_ecosystems) }
  it { is_expected.to have_many(:courses) }

  it { is_expected.to have_many(:books) }
  it { is_expected.to have_many(:chapters) }
  it { is_expected.to have_many(:pages) }
  it { is_expected.to have_many(:exercises) }
  it { is_expected.to have_many(:pools) }

  it { is_expected.to have_many(:to_maps) }
  it { is_expected.to have_many(:from_maps) }

  it { is_expected.to validate_presence_of(:title) }

  context 'with no books' do
    let(:expected_title) { 'Empty Ecosystem' }

    include_examples 'ecosystem specs'
  end

  context 'with a single book' do
    let!(:book)          { FactoryBot.create :content_book, ecosystem: ecosystem }
    before(:each)        { ecosystem.reload }

    let(:expected_title) { "#{book.title} (#{book.cnx_id})" }

    include_examples 'ecosystem specs'
  end
end
