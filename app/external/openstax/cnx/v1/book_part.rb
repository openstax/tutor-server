module OpenStax::Cnx::V1
  class BookPart

    def initialize(hash: {})
      @hash = hash
    end

    attr_reader :hash

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

    def is_unit?(has_parent:)
      # A unit is a part that has other book parts under it (chapters) but is not
      # the root (and hence has a parent).  From `hash` we can't figure out if this part
      # has a parent, so that value must be passed in.
      @is_unit ||= has_parent && contents.any?{ |hash| hash['id'] == 'subcol' }
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

    def visit(visitor:, depth: 0)
      visitor.pre_order_visit(elem: self, depth: depth)
      visitor.in_order_visit(elem: self, depth: depth)
      parts.each do |part|
        part.visit(visitor: visitor, depth: depth+1)
      end
      visitor.post_order_visit(elem: self, depth: depth)
    end

  end
end
