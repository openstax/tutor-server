module OpenStax::Cnx::V1::Fragments
  class Text

    # Used to get the title
    TITLE_CSS = '[data-type="title"]'

    # For fragments missing a proper title
    DEFAULT_TITLE = nil

    def initialize(node:, title: nil)
      @node  = node
      @title = title
    end

    attr_reader :node

    def title
      return @title unless @title.nil?

      @title = node.css(TITLE_CSS).collect{|n| n.try(:content).try(:strip)}
                                  .compact.uniq.join('; ')
      @title = DEFAULT_TITLE if @title.blank?
      @title
    end

    def to_html
      node.to_html
    end

    def visit(visitor:, depth: 0)
      visitor.pre_order_visit(elem: self, depth: depth)
      visitor.in_order_visit(elem: self, depth: depth)
      visitor.post_order_visit(elem: self, depth: depth)
    end

  end
end
