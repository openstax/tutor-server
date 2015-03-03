require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Api::ImportBook, :type => :routine,
                                         :vcr => VCR_OPTS,
                                         :speed => :slow do
  cnx_book_id = '031da8d3-b525-429c-80cf-6c8ed997733a'

  fixture_file = "spec/fixtures/#{cnx_book_id}/tree/contents.json"

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

  it 'creates a new Book structure and Pages and sets their attributes' do
    result = nil
    expect { 
      result = Content::Api::ImportBook.call(cnx_book_id); 
    }.to change{ Content::BookPart.count }.by(35)
    expect(result.errors).to be_empty

    toc = open(fixture_file) { |f| f.read }

    content_book_part = result.outputs.content_book_part

    expect(JSON.parse(content_book_part.content)).to eq JSON.parse(toc)
    test_book_part(content_book_part)
  end

  xit 'adds a path signifier according to subcol structure' do
    bio_book_id = '185cbf87-c72e-48f5-b51e-f14f21b5eabd'
    book_import = Content::Api::ImportBook.call(bio_book_id)
    root_book_part = book_import.outputs.content_book_part

    root_book_part.child_book_parts.each_with_index do |unit, i|
      expect(unit.path).to eq("#{i + 1}")

      unit.child_book_parts.each_with_index do |chapter, idx|
        expect(chapter.path).to eq("#{i + 1}.#{idx + 1}")

        chapter.pages.each_with_index do |page, pidx|
          expect(page.path).to eq("#{i + 1}.#{idx + 1}.#{pidx + 1}")
        end
      end
    end
  end
end
