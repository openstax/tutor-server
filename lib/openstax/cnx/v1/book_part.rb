module OpenStax::Cnx::V1
  class BookPart

    def initialize(hash: {}, is_root: false, book: nil)
      @hash = hash
      @is_root = is_root
      @book = book
    end

    attr_reader :hash, :is_root, :book

    def parsed_title
      @parsed_title ||= OpenStax::Cnx::V1::Baked.parse_title(
        hash.fetch('title') { |key| raise "#{self.class.name} id=#{@id} is missing #{key}" }
      )
    end

    def baked_book_location
      @baked_book_location ||= parsed_title[:book_location]
    end

    def title
      @title ||= parsed_title[:text]
    end

    def contents
      @contents ||= hash.fetch('contents') do |key|
        raise "#{self.class.name} id=#{@id} is missing #{key}"
      end
    end

    def parts
      @parts ||= contents.map do |hash|
        if hash.has_key? 'contents'
          self.class.new(hash: hash, book: book)
        else
          OpenStax::Cnx::V1::Page.new(hash: hash, book: book)
        end
      end
    end

    def is_chapter?
      # A BookPart is a chapter if none of its children are BookParts
      @is_chapter ||= parts.none? { |part| part.is_a?(self.class) }
    end

  end
end
