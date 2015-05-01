require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Book, :type => :external, :vcr => VCR_OPTS do

  cnx_book_id = '7db9aa72-f815-4c3b-9cb6-d50cf5318b58'
  cnx_book_versions = ['@2.2', '@4.3']
  cnx_book_gold_data = {
    '@2.2' => {
      pre_order:  [["Book", 0],
                     ["BookPart", 1],
                       ["BookPart", 2],
                         ["Page", 3],
                           ["Text", 4],
                         ["Page", 3],
                           ["Text", 4], ["Text", 4], ["Exercise", 4], ["Text", 4],
                         ["Page", 3],
                           ["Text", 4], ["Video", 4], ["Exercise", 4], ["Interactive", 4], ["Exercise", 4], ["Text", 4]],
      post_order: [["Text", 4],
                     ["Page", 3],
                   ["Text", 4], ["Text", 4], ["Exercise", 4], ["Text", 4],
                     ["Page", 3],
                   ["Text", 4], ["Video", 4], ["Exercise", 4], ["Interactive", 4], ["Exercise", 4], ["Text", 4],
                     ["Page", 3],
                       ["BookPart", 2],
                         ["BookPart", 1],
                           ["Book", 0]]
    },
    '@4.3' => {
      pre_order:  [["Book", 0],
                     ["BookPart", 1],
                       ["BookPart", 2],
                         ["Page", 3],
                           ["Text", 4],
                         ["Page", 3],
                           ["Text", 4], ["Text", 4], ["Exercise", 4], ["Text", 4],
                         ["Page", 3],
                           ["Text", 4], ["Video", 4], ["Exercise", 4], ["Interactive", 4], ["Exercise", 4], ["Text", 4],
                         ["Page", 3],
                           ["Text", 4], ["Exercise", 4], ["Text", 4], ["Video", 4], ["Exercise", 4], ["Text", 4], ["Text", 4],
                           ["ExerciseChoice", 4],
                             ["Exercise", 5], ["Exercise", 5],
                           ["Text", 4], ["Exercise", 4], ["Text", 4],
                         ["Page", 3],
                           ["Text", 4]],
      post_order: [  ["Text", 4],
                       ["Page", 3],
                     ["Text", 4], ["Text", 4], ["Exercise", 4], ["Text", 4],
                       ["Page", 3],
                     ["Text", 4], ["Video", 4], ["Exercise", 4], ["Interactive", 4], ["Exercise", 4], ["Text", 4],
                       ["Page", 3],
                     ["Text", 4], ["Exercise", 4], ["Text", 4], ["Video", 4], ["Exercise", 4], ["Text", 4], ["Text", 4],
                   ["Exercise", 5], ["Exercise", 5],
                     ["ExerciseChoice", 4],
                     ["Text", 4], ["Exercise", 4], ["Text", 4],
                       ["Page", 3],
                     ["Text", 4],
                       ["Page", 3],
                         ["BookPart", 2],
                           ["BookPart", 1],
                             ["Book", 0]]
    }
  }
  cnx_book_versions.each do |version|
    id = "#{cnx_book_id}#{version}"
    context "with '#{id}' content" do
      it "provides info about the book with the given id" do
        book = OpenStax::Cnx::V1::Book.new(id: id)
        expect(book.id).to eq id
        expect(book.hash).not_to be_blank
        expect(book.title).to eq "Updated Tutor HS Physics Content - legacy"
        expect(book.tree).not_to be_nil
        expect(book.root_book_part).to be_a OpenStax::Cnx::V1::BookPart
      end

      it "accepts a visitor" do
        post_order_gold_data =
        book = OpenStax::Cnx::V1::Book.new(id: id)

        visitor = TestVisitor.new
        book.visit(visitor: visitor)
        expect(visitor.pre_order_visited).to  eq(cnx_book_gold_data[version][:pre_order])
        expect(visitor.in_order_visited).to   eq(cnx_book_gold_data[version][:pre_order]) # <-- not a typo!
        expect(visitor.post_order_visited).to eq(cnx_book_gold_data[version][:post_order])
      end

    end
  end

end

class TestVisitor
  include OpenStax::Cnx::V1::Visitors::Book

  attr_reader :pre_order_visited
  attr_reader :in_order_visited
  attr_reader :post_order_visited

  def initialize
    @pre_order_visited  = []
    @in_order_visited   = []
    @post_order_visited = []
  end

  ## Add pre/in/post order visit methods for each Cnx::Book element type, e.g.:
  ##   def pre_order_visit_book(book:, depth:)
  ##     @pre_order_visited << [book.class.name.demodulize, depth]
  ##   end
  OpenStax::Cnx::V1::Visitors::Book::VISIT_TYPES.each do |visit_order|
    OpenStax::Cnx::V1::Visitors::Book::ELEM_TYPES.each do |elem_type|
      method_body = <<-EOS
        def #{visit_order}_order_visit_#{elem_type}(#{elem_type}:, depth:)
          @#{visit_order}_order_visited << [#{elem_type}.class.name.demodulize, depth]
        end
      EOS
      module_eval(method_body, __FILE__, __LINE__)
    end
  end

end
