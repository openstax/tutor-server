require 'rails_helper'

RSpec.describe Content::Api::GetBookToc, :type => :routine do

  let!(:root_book_part) { FactoryGirl.create(:content_book_part, :standard_contents_1) }

  it "gets the book toc for a 3 level book" do
    result = nil
    expect(result = Content::Api::GetBookToc.call(book_id: root_book_part.book.id))
                      .to_not have_routine_errors

    toc = result.outputs.toc

    expect(toc).to eq(
      [{
        id: 2,
        title: 'unit 1',
        type: 'part',
        children: [
          { 
            id: 3,
            title: 'chapter 1', 
            type: 'part',
            children: [
              { id: 1, title: 'first page', type: 'page' }.stringify_keys,
              { id: 2, title: 'second page', type: 'page' }.stringify_keys
            ]
          }.stringify_keys,
          {
            id: 4,
            title: 'chapter 2',
            type: 'part',
            children: [
              { id: 3, title: 'third page', type: 'page' }.stringify_keys
            ]
          }.stringify_keys
        ] 
      }.stringify_keys]
    )
  end

end