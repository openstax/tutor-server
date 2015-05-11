module OpenStax::Cnx::V1::Fragment
  class Interactive

    # Used to get the title
    TITLE_CSS = '[data-type="title"]'

    # For fragments missing a proper title
    DEFAULT_TITLE = nil

    # CSS to find the simulation url
    URL_CSS = 'a.ost-iframe-embeddable, .os-embed iframe'

    def initialize(node:, title: nil)
      @node  = node
      @title = title
    end

    attr_reader :node

    def title
      @title ||= node.at_css(TITLE_CSS).try(:content).try(:strip) || DEFAULT_TITLE
    end

    def url
      url_node = node.at_css(URL_CSS)
      @url ||= url_node.try(:[], 'href') || url_node.try(:[], 'src')
    end

    def to_html
      # Leave content as-is for now
      @to_html ||= node.to_html
    end

    def visit(visitor:, depth: 0)
      visitor.pre_order_visit(elem: self, depth: depth)
      visitor.in_order_visit(elem: self, depth: depth)
      visitor.post_order_visit(elem: self, depth: depth)
    end

  end
end
