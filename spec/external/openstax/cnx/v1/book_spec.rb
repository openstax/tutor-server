require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Book, :type => :external, :vcr => VCR_OPTS do

  cnx_book_ids = {
    stable: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58@2.2',
    latest: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58'
  }

  cnx_book_ids.each do |name, id|
    context "with #{name.to_s} content" do
      it "provides info about the book with the given id" do
        book = OpenStax::Cnx::V1::Book.new(id: id)
        expect(book.id).to eq id
        expect(book.hash).not_to be_blank
        expect(book.title).to eq "Updated Tutor HS Physics Content - legacy"
        expect(book.tree).not_to be_nil
        expect(book.root_book_part).to be_a OpenStax::Cnx::V1::BookPart
      end
    end
  end

end
