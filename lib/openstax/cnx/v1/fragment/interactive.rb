class OpenStax::Cnx::V1::Fragment
  class Interactive < Embedded

    # CSS to find interactive containers (anything inside may be replaced with an iframe)
    CONTAINER_CSS = 'figure.ost-embed-container, figure:has-descendants("a.os-interactive-link")'

    # CSS to find links to be embedded inside containers
    TAGGED_LINK_CSS = 'a.os-embed, a.os-interactive-link'
    UNTAGGED_LINK_CSS = 'a'

    self.default_width = 960
    self.default_height = 560
    self.iframe_classes += ['interactive']

    # This code is run from lib/openstax/cnx/v1/page.rb during import
    def self.replace_interactive_links_with_iframes(node)
      containers = node.css(CONTAINER_CSS, OpenStax::Cnx::V1::CustomCss.instance)

      containers.each do |container|
        link_node = node.at_css(TAGGED_LINK_CSS) || node.css(UNTAGGED_LINK_CSS).last

        next if link_node.nil?

        # Build iframe based on the link's URL
        iframe = Nokogiri::XML::Node.new('iframe', node.document)
        iframe['src'] = link_node['href']
        iframe['class'] = iframe_classes.join(' ')
        iframe['width'] = default_width
        iframe['height'] = default_height

        # Replace the container with the new iframe
        container.replace(iframe)
      end

      node
    end

  end
end
