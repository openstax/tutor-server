require 'rails_helper'

RSpec.describe Content::ListBooks, type: :routine do
  let(:books) { Content::ListBooks[] }

  context "when no books are present" do
    it "returns no books" do
      expect(books).to be_empty
    end
  end

  context "when books are present" do
    let!(:book1) {
      FactoryGirl.create(:content_book_part, contents: { title: 'Title c' })
    }
    let!(:book2) {
      FactoryGirl.create(:content_book_part, contents: { title: 'Title Z' })
    }
    let!(:book3) {
      FactoryGirl.create(:content_book_part, contents: { title: 'Title a' })
    }

    it "returns all books" do
      expect(books.collect(&:uuid)).to contain_exactly(book1.uuid, book2.uuid, book3.uuid)
    end

    it "sorts returned books by title (ascending, ascii)" do
      expect(books.collect(&:title)).to eq(['Title Z', 'Title a', 'Title c'])
    end
  end
end
