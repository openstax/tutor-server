module Content
  class Manifest < OpenStruct
    def self.from_yaml(yaml)
      new(YAML.load(yaml))
    end

    def to_h
      super.deep_stringify_keys
    end

    def to_yaml
      to_h.to_yaml
    end

    def books
      super.to_a.map { |book_hash| ::Content::Manifest::Book.new(book_hash) }
    end

    def errors
      return @errors unless @errors.nil?

      @errors = []
      @errors << 'Manifest ecosystem has no title' if title.blank?
      @errors << 'Manifest ecosystem has no books' if books.empty?
      books.each { |book| @errors += book.errors }

      @errors
    end

    def valid?
      errors.empty?
    end
  end
end
