module OpenStax::Cnx::V1
  class Fragment::Embedded < Fragment

    # Used to get the title
    TITLE_CSS = '[data-type="title"]'

    # Used to get the title if there are no title nodes
    LABEL_ATTRIBUTE = 'data-label'

    # CSS to find embedded element containers (will be replaced with iframe)
    CONTAINER_CSS = '.os-interactive-link, .ost-embed-container'

    # CSS to find embedded content urls
    TAGGED_URL_CSS = 'iframe.os-embed, a.os-embed, .os-embed iframe, .os-embed a'
    UNTAGGED_URL_CSS = 'iframe, a'

    class_attribute :default_width, :default_height

    attr_reader :url, :width, :height, :to_html

    # This code is run in page.rb during import
    def self.replace_embed_links_with_iframes(node)
      containers = node.css(CONTAINER_CSS)

      containers.each do |container|
        url_node = get_url_node(container)

        case url_node.try(:name)
        when 'iframe'
          # Reuse url node's iframe
          container.replace(url_node)
        when 'a'
          # Build iframe based on the link's URL
          iframe = Nokogiri::XML::Node.new('iframe', node.document)
          iframe['src'] = url
          iframe['width'] = width
          iframe['height'] = height

          # Save the url node's parent
          parent = url_node.parent
          # Replace the url node with its text
          url_node.replace(url_node.inner_html)
          # Replace the container with the new iframe or append it to the parent node
          container.replace(iframe)
        end
      end

      node
    end

    def initialize(node:, title: nil, labels: nil)
      super

      @title ||= begin
        title_nodes = node.css(TITLE_CSS)
        title_nodes.empty? ? node.attr(LABEL_ATTRIBUTE) :
                             title_nodes.map{ |node| node.content.strip }.uniq.join('; ')
      end

      url_node = get_url_node(node)

      @width = url_node.try(:[], 'width') || default_width
      @height = url_node.try(:[], 'height') || default_height

      @url = url_node.try(:[], 'src') || url_node.try(:[], 'href')

      @to_html = node.to_html
    end

    def blank?
      url.blank?
    end

    protected

    def get_url_node(node)
      node.at_css(TAGGED_URL_CSS) || node.css(UNTAGGED_URL_CSS).last
    end

  end
end
