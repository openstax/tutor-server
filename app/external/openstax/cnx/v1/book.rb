module OpenStax::Cnx::V1
  class Book

    def initialize(id: nil, hash: nil, title: nil,
                   tree: nil, root_book_part: nil)
      @id             = id
      @hash           = hash
      @title          = title
      @tree           = tree
      @root_book_part = root_book_part
    end

    attr_reader :id

    def hash
      @hash ||= OpenStax::Cnx::V1.fetch(id)
    end

    def title
      @title ||= hash.fetch('title') { |key|
        raise "Book id=#{id} is missing #{key}"
      }
    end

    def tree
      @tree ||= hash.fetch('tree') { |key|
        raise "Book id=#{id} is missing #{key}"
      }
    end

    def root_book_part
      @root_book_part ||= BookPart.new(hash: tree)
    end

    def visit(visitor:, depth: 0)
      visitor.pre_order_visit_book(book: self, depth: depth)
      visitor.visit_book(book: self, depth: depth)
      root_book_part.visit(visitor: visitor, depth: depth+1)
      visitor.post_order_visit_book(book: self, depth: depth)
    end

  end
end
