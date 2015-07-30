require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Book, type: :external, vcr: VCR_OPTS do

  cnx_book_id = '93e2b09d-261c-4007-a987-0b3062fe154b'
  cnx_book_gold_data = {
    pre_order:  [
      ["Book", 0],
        ["BookPart", 1],
          ["BookPart", 2],
          ["BookPart", 2],
          ["BookPart", 2],
            ["Page", 3],
              ["Text", 4],
            ["Page", 3],
              ["Text", 4], ["Feature", 4],
                ["Interactive", 5], ["Exercise", 5],
              ["Text", 4], ["Feature", 4],
                ["Text", 5],
              ["ExerciseChoice", 4],
                ["Exercise", 5], ["Exercise", 5],
              ["Feature", 4],
                ["Video", 5], ["Exercise", 5],
            ["Page", 3],
              ["Text", 4], ["Feature", 4],
                ["Interactive", 5], ["Exercise", 5],
              ["Text", 4], ["Feature", 4],
                ["Text", 5], ["Exercise", 5],
              ["Feature", 4],
                ["Text", 5],
              ["Text", 4], ["Feature", 4],
                ["Text", 5], ["Exercise", 5],
              ["Feature", 4],
                ["Text", 5],
              ["ExerciseChoice", 4],
                ["Exercise", 5], ["Exercise", 5],
          ["BookPart", 2],
            ["Page", 3],
              ["Text", 4],
            ["Page", 3],
              ["Text", 4],
            ["Page", 3],
              ["Text", 4], ["Feature", 4],
                ["Video", 5], ["Exercise", 5],
              ["Feature", 4],
                ["Interactive", 5], ["Exercise", 5],
            ["Page", 3],
              ["Text", 4], ["Feature", 4],
                ["Video", 5], ["Exercise", 5],
              ["Feature", 4],
                ["Text", 5],
              ["ExerciseChoice", 4],
                ["Exercise", 5], ["Exercise", 5],
            ["Page", 3],
              ["Text", 4],
              ["Feature", 4],
                ["Text", 5], ["Exercise", 5],
              ["Feature", 4],
                ["Video", 5], ["Exercise", 5],
              ["Feature", 4],
                ["Text", 5],
              ["ExerciseChoice", 4],
                ["Exercise", 5], ["Exercise", 5]],
    post_order: [
          ["BookPart", 2],
          ["BookPart", 2],
              ["Text", 4],
            ["Page", 3],
              ["Text", 4],
                ["Interactive", 5], ["Exercise", 5],
              ["Feature", 4], ["Text", 4],
                ["Text", 5],
              ["Feature", 4],
                ["Exercise", 5], ["Exercise", 5],
              ["ExerciseChoice", 4],
                ["Video", 5], ["Exercise", 5],
              ["Feature", 4],
            ["Page", 3],
              ["Text", 4],
                ["Interactive", 5], ["Exercise", 5],
              ["Feature", 4], ["Text", 4],
                ["Text", 5], ["Exercise", 5],
              ["Feature", 4],
                ["Text", 5],
              ["Feature", 4], ["Text", 4],
                ["Text", 5], ["Exercise", 5],
              ["Feature", 4],
                ["Text", 5],
              ["Feature", 4],
                ["Exercise", 5], ["Exercise", 5],
              ["ExerciseChoice", 4],
            ["Page", 3],
          ["BookPart", 2],
              ["Text", 4],
            ["Page", 3],
              ["Text", 4],
            ["Page", 3],
              ["Text", 4],
                ["Video", 5], ["Exercise", 5],
              ["Feature", 4],
                ["Interactive", 5], ["Exercise", 5],
              ["Feature", 4],
            ["Page", 3],
              ["Text", 4],
                ["Video", 5], ["Exercise", 5],
              ["Feature", 4],
                ["Text", 5],
              ["Feature", 4],
                ["Exercise", 5], ["Exercise", 5],
              ["ExerciseChoice", 4],
            ["Page", 3],
              ["Text", 4],
                ["Text", 5], ["Exercise", 5],
              ["Feature", 4],
                ["Video", 5], ["Exercise", 5],
              ["Feature", 4],
                ["Text", 5],
              ["Feature", 4],
                ["Exercise", 5], ["Exercise", 5],
              ["ExerciseChoice", 4],
            ["Page", 3],
          ["BookPart", 2],
        ["BookPart", 1],
      ["Book", 0]
    ]
  }

  let!(:expected_book_url) {
    'https://archive-staging-tutor.cnx.org/contents/93e2b09d-261c-4007-a987-0b3062fe154b'
  }

  it "provides info about the book with the given id" do
    book = OpenStax::Cnx::V1::Book.new(id: cnx_book_id)
    expect(book.id).to eq cnx_book_id
    expect(book.hash).not_to be_blank
    expect(book.url).to eq expected_book_url
    expect(book.uuid).to eq '93e2b09d-261c-4007-a987-0b3062fe154b'
    expect(book.version).to eq '3.6'
    expect(book.title).to eq 'Physics'
    expect(book.tree).not_to be_nil
    expect(book.root_book_part).to be_a OpenStax::Cnx::V1::BookPart
  end

  it "accepts a visitor" do
    book = OpenStax::Cnx::V1::Book.new(id: cnx_book_id)

    visitor = TestVisitor.new
    book.visit(visitor: visitor)
    expect(visitor.pre_order_visited).to  eq(cnx_book_gold_data[:pre_order])
    expect(visitor.in_order_visited).to   eq(cnx_book_gold_data[:pre_order]) # <-- not a typo!
    expect(visitor.post_order_visited).to eq(cnx_book_gold_data[:post_order])
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

  ## Add pre/in/post order visit methods for each Cnx::Book element type, e.g.:
  ##   def pre_order_visit_book(book:, depth:)
  ##     @pre_order_visited << [book.class.name.demodulize, depth]
  ##   end
  OpenStax::Cnx::V1::BookVisitor::VISIT_TYPES.each do |visit_order|
    OpenStax::Cnx::V1::BookVisitor::ELEM_TYPES.each do |elem_type|
      method_body = <<-EOS
        def #{visit_order}_order_visit_#{elem_type}(#{elem_type}:, depth:)
          @#{visit_order}_order_visited << [#{elem_type}.class.name.demodulize, depth]
        end
      EOS
      module_eval(method_body, __FILE__, __LINE__)
    end
  end

end
