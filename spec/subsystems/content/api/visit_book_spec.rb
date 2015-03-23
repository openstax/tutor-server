require 'rails_helper'

RSpec.describe Content::Api::VisitBook, :type => :routine do

  it "should get the TOC with the TOC option" do
    root_book_part = FactoryGirl.create(:content_book_part, :standard_contents_1)
    result = Content::Api::VisitBook.call(book: root_book_part.book, visitor_names: [:toc])
    binding.pry
  end

end

      