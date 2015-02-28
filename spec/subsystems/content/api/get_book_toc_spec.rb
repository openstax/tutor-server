require 'rails_helper'

RSpec.describe Content::Api::GetBookToc, :type => :routine do

  let!(:book) { FactoryGirl.create :entity_book }
  let!(:root_book_part) { 
    FactoryGirl.create(
      :content_book_part, 
      book: book,
      contents: {
        title: 'unit 1',
        book_parts: [
          {
            title: 'chapter 1',
            pages: [
              { title: 'first page' },
              { title: 'second page' }
            ]
          },
          {
            title: 'chapter 2',
            pages: [
              { title: 'third page' }
            ]
          }
        ]
      }
    )
  }

  it "gets the book toc for a 3 level book" do
    result = nil
    expect(result = Content::Api::GetBookToc.call(book_id: book.id)).to_not have_routine_errors

    toc = result.outputs.toc.to_hash

    expect(toc).to eq(
      {
        id: 1,
        title: 'unit 1',
        type: 'part',
        children: [
          { 
            id: 2,
            title: 'chapter 1', 
            type: 'part',
            children: [
              { id: 1, title: 'first page', type: 'page' }.stringify_keys,
              { id: 2, title: 'second page', type: 'page' }.stringify_keys
            ]
          }.stringify_keys,
          {
            id: 3,
            title: 'chapter 2',
            type: 'part',
            children: [
              { id: 3, title: 'third page', type: 'page' }.stringify_keys
            ]
          }.stringify_keys
        ] 
      }.stringify_keys
    )
  end

end