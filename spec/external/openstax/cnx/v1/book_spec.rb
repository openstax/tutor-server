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

  it "accepts a visitor" do
    pre_order_gold_data = [["Book", 0], ["BookPart", 1], ["BookPart", 2], ["Page", 3], ["Text", 4],
                                                                          ["Page", 3], ["Text", 4],
                                                                                       ["Text", 4],
                                                                                       ["Exercise", 4],
                                                                                       ["Text", 4],
                                                                          ["Page", 3], ["Text", 4],
                                                                                       ["Video", 4],
                                                                                       ["Exercise", 4],
                                                                                       ["Text", 4],
                                                                                       ["Exercise", 4],
                                                                                       ["Text", 4]]
    in_order_gold_data = pre_order_gold_data
    post_order_gold_data = [["Text", 4], ["Page", 3],
                            ["Text", 4],
                            ["Text", 4],
                            ["Exercise", 4],
                            ["Text", 4], ["Page", 3],
                            ["Text", 4],
                            ["Video", 4],
                            ["Exercise", 4],
                            ["Text", 4],
                            ["Exercise", 4],
                            ["Text", 4], ["Page", 3], ["BookPart", 2], ["BookPart", 1], ["Book", 0]]
    book = OpenStax::Cnx::V1::Book.new(id: cnx_book_ids[:stable])

    visitor = TestVisitor.new
    book.visit(visitor: visitor)
    expect(visitor.pre_order_visited).to  eq(pre_order_gold_data)
    expect(visitor.in_order_visited).to   eq(in_order_gold_data)
    expect(visitor.post_order_visited).to eq(post_order_gold_data)
  end

end

class TestVisitor
  include OpenStax::Cnx::V1::BookVisitor

  attr_reader :pre_order_visited
  attr_reader :in_order_visited
  attr_reader :post_order_visited

  def initialize
    @pre_order_visited  = []
    @in_order_visited   = []
    @post_order_visited = []
  end

  def pre_order_visit_book(book:, depth:)
    @pre_order_visited << [book.class.name.demodulize, depth]
  end
  def pre_order_visit_book_part(book_part:, depth:)
    @pre_order_visited << [book_part.class.name.demodulize, depth]
  end
  def pre_order_visit_page(page:, depth:)
    @pre_order_visited << [page.class.name.demodulize, depth]
  end
  def pre_order_visit_fragment_text(fragment_text:, depth:)
    @pre_order_visited << [fragment_text.class.name.demodulize, depth]
  end
  def pre_order_visit_fragment_exercise(fragment_exercise:, depth:)
    @pre_order_visited << [fragment_exercise.class.name.demodulize, depth]
  end

  def visit_book(book:, depth:)
    @in_order_visited << [book.class.name.demodulize, depth]
  end
  def visit_book_part(book_part:, depth:)
    @in_order_visited << [book_part.class.name.demodulize, depth]
  end
  def visit_page(page:, depth:)
    @in_order_visited << [page.class.name.demodulize, depth]
  end
  def visit_fragment_text(fragment_text:, depth:)
    @in_order_visited << [fragment_text.class.name.demodulize, depth]
  end
  def visit_fragment_exercise(fragment_exercise:, depth:)
    @in_order_visited << [fragment_exercise.class.name.demodulize, depth]
  end

  def post_order_visit_book(book:, depth:)
    @post_order_visited << [book.class.name.demodulize, depth]
  end
  def post_order_visit_book_part(book_part:, depth:)
    @post_order_visited << [book_part.class.name.demodulize, depth]
  end
  def post_order_visit_page(page:, depth:)
    @post_order_visited << [page.class.name.demodulize, depth]
  end
  def post_order_visit_fragment_text(fragment_text:, depth:)
    @post_order_visited << [fragment_text.class.name.demodulize, depth]
  end
  def post_order_visit_fragment_exercise(fragment_exercise:, depth:)
    @post_order_visited << [fragment_exercise.class.name.demodulize, depth]
  end
end
