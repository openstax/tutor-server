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

    def to_s(indent: 0)
      s = "BOOK #{id}\n"
      s << root_book_part.to_s(indent: indent)
    end

  end
end
