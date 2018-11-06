module OpenStax::Cnx::V1
  class Book

    def initialize(id: nil, hash: nil, title: nil, tree: nil, root_book_part: nil)
      @id             = id
      @hash           = hash
      @title          = title
      @tree           = tree
      @root_book_part = root_book_part
    end

    attr_reader :id

    def url
      @url ||= OpenStax::Cnx::V1.archive_url_for(id)
    end

    def baked
      @baked ||= hash.fetch('baked', nil)
    end

    def hash
      @hash ||= OpenStax::Cnx::V1.fetch(url)
    end

    def uuid
      @uuid ||= hash.fetch('id') { |key|
        raise "Book id=#{id} is missing #{key}"
      }
    end

    def short_id
      @short_id ||= hash.fetch('shortId', nil)
    end

    def version
      @version ||= hash.fetch('version') { |key|
        raise "Book id=#{id} is missing #{key}"
      }
    end

    def canonical_url
      @canonical_url ||= OpenStax::Cnx::V1.archive_url_for("#{uuid}@#{version}")
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
      @root_book_part ||= BookPart.new(hash: tree, is_root: true, book: self)
    end

  end
end
