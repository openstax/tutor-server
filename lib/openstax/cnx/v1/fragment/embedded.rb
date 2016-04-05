module OpenStax::Cnx::V1
  class Fragment::Embedded < Fragment

    class_attribute :default_width, :default_height

    # CSS to find the embedded element container (will be replaced with iframe)
    CONTAINER_CSS = '.ost-embed-container'
    MEDIA_CSS = '[data-type="media"]'

    # CSS to find the embedded content url
    TAGGED_URL_CSS = 'iframe.os-embed, a.os-embed, .os-embed iframe, .os-embed a'
    UNTAGGED_URL_CSS = 'iframe, a'

    def url
      @url ||= url_node.try(:[], 'src')
      return @url unless @url.nil?

      # No source attribute found, so try href
      original_url = url_node.try(:[], 'href')
      return nil if original_url.nil? || original_url =~ /^#/

      # This is an anchor, which Page does not convert to https, so redo the conversion here
      uri = Addressable::URI.parse(original_url)
      uri.scheme = 'https'
      @url = uri.to_s
    end

    def width
      @width ||= url_node.try(:[], 'width') || default_width
    end

    def height
      @height ||= url_node.try(:[], 'height') || default_height
    end

    def to_html
      return @to_html unless @to_html.nil?

      case url_node.name
      when 'iframe'
        # Reuse url node's iframe
        container.replace(url_node) unless container.nil?
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
        container.nil? ? parent.add_next_sibling(iframe) : container.replace(iframe)
      end

      @to_html ||= node.to_html
    end

    def blank?
      url.blank?
    end

    protected

    def container
      @container ||= node.at_css(CONTAINER_CSS) || node.at_css(MEDIA_CSS)
    end

    def url_node
      @url_node ||= node.at_css(TAGGED_URL_CSS) || node.css(UNTAGGED_URL_CSS).last
    end

  end
end
