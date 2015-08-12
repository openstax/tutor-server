module Content
  class Tag

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer
    end

    def value
      verify_and_return @strategy.value, klass: String
    end

    def tag_type
      verify_and_return @strategy.tag_type, klass: String
    end

    def name
      verify_and_return @strategy.name, klass: String, allow_nil: true
    end

    def description
      verify_and_return @strategy.description, klass: String, allow_nil: true
    end

    def book_location
      verify_and_return @strategy.book_location, klass: Array
    end

    def data
      verify_and_return @strategy.data, klass: String, allow_nil: true
    end

    def visible?
      !!@strategy.visible?
    end

    def to_s
      value
    end

  end
end
