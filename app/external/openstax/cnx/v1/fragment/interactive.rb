module OpenStax::Cnx::V1::Fragment
  class Interactive

    # Used to get the title
    TITLE_CSS = '[data-type="title"]'

    # For fragments missing a proper title
    DEFAULT_TITLE = nil

    # CSS to find the interactive
    INTERACTIVE_CSS = '.os-embed'

    def initialize(node:, title: nil)
      @node  = node
      @title = title
    end

    attr_reader :node

    def title
      @title ||= node.at_css(TITLE_CSS).try(:content).try(:strip) || \
                 DEFAULT_TITLE
    end

    def interactive(node = node)
      @interactive ||= node.at_css(INTERACTIVE_CSS)

    end

    def to_html
      # Remove the media tag and replace it with just its text
      if @to_html.nil?
        node_copy = node.dup
        interactive_copy = interactive(node = node_copy)
        interactive_copy.replace(interactive_copy.text)
        @to_html = node_copy.to_html
      end
      @to_html
    end

    def url
      @url ||= interactive.try(:xpath, 'iframe/@src').to_s
    end

    def visit(visitor:, depth: 0)
      visitor.pre_order_visit(elem: self, depth: depth)
      visitor.in_order_visit(elem: self, depth: depth)
      visitor.post_order_visit(elem: self, depth: depth)
    end

  end
end
