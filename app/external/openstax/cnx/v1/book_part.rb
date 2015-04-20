module OpenStax::Cnx::V1
  class BookPart

    def initialize(hash: {}, chapter_section: nil, title: nil, contents: nil, parts: nil)
      @hash            = hash
      @chapter_section = chapter_section
      @title           = title
      @contents        = contents
      @parts           = parts
    end

    attr_reader :hash, :chapter_section

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

    def parts
      path_prefix = chapter_section.blank? ? "" : "#{chapter_section}."
      book_part_index = 0
      page_index = 0

      @parts ||= contents.collect do |hash|
        if hash['id'] == 'subcol'
          BookPart.new(hash: hash,
                       chapter_section: "#{path_prefix}#{book_part_index += 1}")
        else
          Page.new(hash: hash,
                   chapter_section: "#{path_prefix}#{page_index += 1}",
                   book_part_title: title)
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
