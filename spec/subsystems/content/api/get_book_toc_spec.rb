require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Api::GetBookToc, :type => :routine, :vcr => VCR_OPTS do

  cnx_book_infos = { stable: { id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58@1.4' },
                     latest: { id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58' } }

  cnx_book_infos.each do |name, info|
    context "for the #{name.to_s} version" do
      let!(:book)        {
        Content::Api::ImportBook.call(info[:id]).outputs.book
      }

      it "gets the book toc" do
        result = Content::Api::GetBookToc.call(book_id: book.id)
        expect(result).to_not have_routine_errors
        toc = result.outputs.toc.to_hash

        expect(toc).to eq(
          { "id"=>1,
            "title"=>"Updated Tutor HS Physics Content - legacy",
            "type"=>"part",
            "children"=> [
              {"id"=>2,
               "title"=>"Forces and Newton's Laws of Motion",
               "type"=>"part",
               "children"=> [
                 {"id"=>1, "title"=>"Introduction", "type"=>"page"},
                 {"id"=>2, "title"=>"Force", "type"=>"page"}
                ]
              }
            ]
          }
        )
      end
    end
  end

end
