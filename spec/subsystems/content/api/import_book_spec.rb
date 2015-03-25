require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Api::ImportBook, :type => :routine, :vcr => VCR_OPTS do

  # Store version differences in this hash
  cnx_book_infos = {
    stable: { id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58@1.4' },
    latest: { id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58' }
  }

  cnx_books = HashWithIndifferentAccess[cnx_book_infos.collect do |name, info|
    [name, OpenStax::Cnx::V1::Book.new(info)]
  end ]

  # Recursively tests the given book and its children
  def test_book_part(book_part)
    expect(book_part).to be_persisted
    expect(book_part.title).not_to be_blank
    expect(book_part.child_book_parts.to_a + book_part.pages.to_a).not_to be_empty

    book_part.child_book_parts.each do |cbp|
      next if cbp == book_part
      test_book_part(cbp)
    end

    book_part.pages.each do |page|
      expect(page).to be_persisted
      expect(page.title).not_to be_blank
    end
  end

  cnx_books.each do |name, book|
    context "with the #{name.to_s} content" do

      before(:each)          { OpenStax::BigLearn::V1.use_fake_client }
      let!(:biglearn_client) { OpenStax::BigLearn::V1.fake_client }

      it 'creates a new Book structure and Pages and sets their attributes' do
        result = nil
        expect {
          result = Content::Api::ImportBook.call(cnx_book: book);
        }.to change{ Content::BookPart.count }.by(2)
        expect(result.errors).to be_empty

        book_part = result.outputs.book_part

        # TODO: Cache TOC and check it here
        test_book_part(book_part)

        expect(biglearn_client.store_exercises_copy).to_not be_empty
      end

      it 'adds a path signifier according to subcol structure' do
        book_import = Content::Api::ImportBook.call(cnx_book: book)
        root_book_part = book_import.outputs.book_part

        root_book_part.child_book_parts.each_with_index do |chapter, i|
          expect(chapter.path).to eq("#{i + 1}")

          chapter.pages.each_with_index do |page, pidx|
            expect(page.path).to eq("#{i + 1}.#{pidx + 1}")
          end
        end
      end
    end
  end

end
