module OpenStax::Cnx::V1
  class BookPart

    def initialize(hash: {}, is_root: false)
      @hash = hash
      @is_root = is_root
    end

    attr_reader :hash, :is_root

    def title
      @title ||= hash.fetch('title') { |key|
        raise "#{self.class.name} id=#{id} is missing #{key}"
      }
    end

    def contents
      @contents ||= hash.fetch('contents') { |key|
        raise "#{self.class.name} id=#{id} is missing #{key}"
      }
    end

    def parts
      @parts ||= contents.map do |hash|
        if hash.has_key? 'contents'
          self.class.new(hash: hash)
        else
          OpenStax::Cnx::V1::Page.new(hash: hash)
        end
      end
    end

    def is_chapter?
      # A BookPart is a chapter if none of its children are BookParts
      @is_chapter ||= parts.none? { |part| part.is_a?(self.class) }
    end

  end
end
