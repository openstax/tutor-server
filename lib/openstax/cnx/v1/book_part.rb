module OpenStax::Cnx::V1
  class BookPart

    def initialize(hash: {}, is_root: false)
      @hash = hash
      @is_root = is_root
    end

    attr_reader :hash, :is_root

    def title
      @title ||= hash.fetch('title') { |key|
        raise "BookPart id=#{id} is missing #{key}"
      }
    end

    def contents
      @contents ||= hash.fetch('contents') { |key|
        raise "BookPart id=#{id} is missing #{key}"
      }
    end

    def is_chapter?
      # A collection is a chapter if it has no subcollections
      @is_chapter ||= contents.none?{ |hash| hash['id'] == 'subcol' }
    end

    def parts
      @parts ||= contents.collect do |hash|
        if hash['id'] == 'subcol'
          BookPart.new(hash: hash)
        else
          OpenStax::Cnx::V1::Page.new(hash: hash)
        end
      end
    end

  end
end
