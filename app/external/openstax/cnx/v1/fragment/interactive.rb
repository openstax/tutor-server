module OpenStax::Cnx::V1::Fragment
  class Interactive

    # Used to get the title
    TITLE_CSS = '[data-type="title"]'

    # For fragments missing a proper title
    DEFAULT_TITLE = nil

    # CSS to find the simulation container (will be replaced with iframe)
    CONTAINER_CSS = '.os-iframe-embeddable, .os-embed'

    # XPath to find the simulation url
    URL_XPATH = './/a/@href | .//iframe/@src'

    def initialize(node:, title: nil)
      @node  = node
      @title = title
    end

    attr_reader :node

    def title
      @title ||= node.at_css(TITLE_CSS).try(:content).try(:strip) || DEFAULT_TITLE
    end

    def url
      @url ||= container.at_xpath(URL_XPATH).value
    end

    def to_html
      return @to_html unless @to_html.nil?

      # Replace container tag with iframe with hardcoded width and height
      iframe = Nokogiri::XML::Node.new('iframe', node.document)
      iframe['src'] = url
      iframe['width'] = 960
      iframe['height'] = 500
      container.replace(iframe)

      @to_html ||= node.to_html
    end

    def visit(visitor:, depth: 0)
      visitor.pre_order_visit(elem: self, depth: depth)
      visitor.in_order_visit(elem: self, depth: depth)
      visitor.post_order_visit(elem: self, depth: depth)
    end

    protected

    def container
      @container ||= node.at_css(CONTAINER_CSS)
    end

  end
end
