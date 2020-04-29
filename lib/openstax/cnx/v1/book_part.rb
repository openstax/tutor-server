module OpenStax::Cnx::V1
  class BookPart
    def initialize(hash: {}, is_root: false, book: nil)
      @hash = hash
      @is_root = is_root
      @book = book
    end

    attr_reader :hash, :is_root, :book

    def parsed_title
      @parsed_title ||= OpenStax::Cnx::V1::Title.new hash.fetch('title')
    end

    def book_location
      @book_location ||= parsed_title.book_location
    end

    def title
      @title ||= parsed_title.text
    end

    # Old content used to have id == "subcol" for units and chapters
    # If we encounter that, just assign a random UUID to them
    def uuid
      @uuid ||= begin
        uuid = hash['id']
        uuid.nil? || uuid == 'subcol' ? SecureRandom.uuid : uuid.split('@').first
      end
    end

    def contents
      @contents ||= hash.fetch('contents')
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
  end
end
