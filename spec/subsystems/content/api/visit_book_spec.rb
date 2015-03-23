require 'rails_helper'

RSpec.describe Content::Api::VisitBook, :type => :routine do

  it "should get the TOC with the TOC option" do
    root_book_part = FactoryGirl.create(:content_book_part, :standard_contents_1)
    result = Content::Api::VisitBook.call(book: root_book_part.book, visitor_names: [:toc])

    expect(result.outputs.toc).to eq([{
      'id' => 2,
      'title' => 'unit 1',
      'type' => 'part',
      'children' => [
        {
          'id' => 3, 
          'title' => 'chapter 1',
          'type' => 'part',
          'children' => [
            {
              'id' => 1,
              'title' => 'first page',
              'type' => 'page'
            },
            {
              'id' => 2,
              'title' => 'second page',
              'type' => 'page'
            }
          ]
        },
        {
          'id' => 4,
          'title' => 'chapter 2',
          'type' => 'part',
          'children' => [
            {
              'id' => 3, 
              'title' => 'third page',
              'type' => 'page'
            }
          ]
        }
      ]      
    }])
  end

end

      