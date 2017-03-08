require 'rails_helper'

RSpec.shared_examples "ecosystem specs" do
  it 'can create a manifest hash' do
    expect(ecosystem.manifest_hash).to eq(
      {
        title: ecosystem.title,
        books: ecosystem.books.map(&:manifest_hash)
      }
    )
  end

  it 'has the correct title' do
    books = ecosystem.books
    expected_title = "#{books.map(&:title).join('; ')} (#{books.map(&:cnx_id).join('; ')})"
    expect(ecosystem.title).to eq expected_title
  end
end

RSpec.describe Content::Models::Ecosystem, type: :model do
  subject(:ecosystem) { FactoryGirl.create :content_ecosystem }

  it { is_expected.to have_many(:course_ecosystems).dependent(:destroy) }
  it { is_expected.to have_many(:courses) }

  it { is_expected.to have_many(:books).dependent(:destroy) }
  it { is_expected.to have_many(:chapters) }
  it { is_expected.to have_many(:pages) }
  it { is_expected.to have_many(:exercises) }
  it { is_expected.to have_many(:pools) }

  it { is_expected.to have_many(:to_maps).dependent(:destroy) }
  it { is_expected.to have_many(:from_maps).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:title) }

  context 'with no books' do
    let(:expected_title) { 'Empty Ecosystem' }

    it 'can return its title' do
      expect(ecosystem.title).to eq expected_title
    end

    it 'can create a manifest hash' do
      expect(ecosystem.manifest_hash).to eq(
        {
          title: expected_title,
          books: []
        }
      )
    end
  end

  context 'with a single book' do
    let!(:book)          { FactoryGirl.create :content_book, ecosystem: ecosystem }
    before(:each)        { ecosystem.reload }

    let(:expected_title) { "#{book.title} (#{book.cnx_id})" }

    it 'can return its title' do
      expect(ecosystem.title).to eq expected_title
    end

    it 'can create a manifest hash' do
      expect(ecosystem.manifest_hash).to eq(
        {
          title: expected_title,
          books: [book.manifest_hash]
        }
      )
    end
  end
end
