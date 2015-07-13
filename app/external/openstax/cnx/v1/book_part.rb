module OpenStax::Cnx::V1
  class BookPart

    def initialize(hash: {}, chapter_section: [], title: nil,
                   contents: nil, parts: nil, initial_child_book_part_index: 1)
      @hash                       = hash
      @chapter_section            = chapter_section
      @title                      = title
      @contents                   = contents
      @parts                      = parts
      @next_child_book_part_index = initial_child_book_part_index
    end

    attr_reader :hash
    attr_accessor :chapter_section

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
      # A BookPart is a chapter if it has no BookPart children
      @is_chapter ||= contents.none?{ |hash| hash['id'] == 'subcol' }
    end

    def parts
      return @parts unless @parts.nil?

      page_index = 0
      previous_bp = nil

      @parts = contents.collect do |hash|
        if hash['id'] == 'subcol'
          bp = BookPart.new(
            hash: hash,
            chapter_section: chapter_section,
            initial_child_book_part_index: previous_bp.try(
              :next_sibling_initial_child_book_part_index
            ) || 1
          )
          if bp.is_chapter?
            bp.chapter_section += [@next_child_book_part_index]
            @next_child_book_part_index += 1
          end
          previous_bp = bp
          bp
        else
          page = OpenStax::Cnx::V1::Page.new(hash: hash)
          page_index -= 1 if page.is_intro?
          page.chapter_section = chapter_section + [page_index += 1]
          page
        end
      end
    end

    def next_sibling_initial_child_book_part_index
      parts
      @next_child_book_part_index
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
