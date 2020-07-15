module OpenStax::Cnx::V1
  class Book
    def initialize(id: nil, hash: nil, title: nil, tree: nil, root_book_part: nil, canonical_url: nil)
      @id             = id
      @hash           = hash
      @title          = title
      @tree           = tree
      @root_book_part = root_book_part
      @canonical_url  = canonical_url
    end

    attr_reader :id

    def url
      @url ||= OpenStax::Cnx::V1.archive_url_for(id)
    end

    def baked
      @baked ||= hash['baked']
    end

    def collated
      @collated ||= hash.fetch('collated', false)
    end

    def hash
      @hash ||= OpenStax::Cnx::V1.fetch(url)
    end

    def uuid
      @uuid ||= hash.fetch('id')
    end

    def short_id
      @short_id ||= hash['shortId']
    end

    def version
      @version ||= hash.fetch('version')
    end

    def canonical_url
      @canonical_url ||= OpenStax::Cnx::V1.archive_url_for("#{uuid}@#{version}")
    end

    def title
      @title ||= hash.fetch('title')
    end

    def tree
      @tree ||= hash.fetch('tree')
    end

    def root_book_part
      @root_book_part ||= BookPart.new(hash: tree, is_root: true, book: self)
    end
  end
end
