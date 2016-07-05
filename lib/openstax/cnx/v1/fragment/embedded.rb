module OpenStax::Cnx::V1
  class Fragment::Embedded < Fragment

    # Used to get the title
    TITLE_CSS = '[data-type="title"]'

    # Used to get the title if there are no title nodes
    LABEL_ATTRIBUTE = 'data-label'

    # CSS to find embedded content urls
    TAGGED_URL_CSS = 'iframe.os-embed, a.os-embed, .os-embed iframe, .os-embed a'
    UNTAGGED_URL_CSS = 'iframe, a'

    class_attribute :iframe_classes, :default_width, :default_height

    self.iframe_classes = ['os-embed']

    attr_reader :url, :width, :height, :to_html

    def initialize(node:, title: nil, labels: nil)
      super

      @title ||= begin
        title_nodes = node.css(TITLE_CSS)
        title_nodes.empty? ? node.attr(LABEL_ATTRIBUTE) :
                             title_nodes.map{ |node| node.content.strip }.uniq.join('; ')
      end

      url_node = node.at_css(TAGGED_URL_CSS) || node.css(UNTAGGED_URL_CSS).last

      if url_node && url_node.name == 'iframe'
        @width  = url_node['width']
        @height = url_node['height']
        @url    = url_node['src'] || url_node['href']

        node_classes = url_node['class'].to_s.split(' ') + iframe_classes
        url_node['class'] = node_classes.uniq.join(' ')

        # To always force the default iframe size, change ||= to =
        url_node['width'] ||= default_width
        url_node['height'] ||= default_height
      end

      @width  ||= default_width
      @height ||= default_height
      @to_html = node.to_html
    end

    def blank?
      url.blank?
    end

  end
end
