module OpenStax::Cnx::V1
  class Fragment::Reading < Fragment
    attr_reader :to_html

    def initialize(node:, title: nil, labels: nil, reference_view_url: nil)
      super node: node, title: title, labels: labels

      node.css('[href]').each do |link|
        href = link.attributes['href']
        uri = Addressable::URI.parse(href.value) rescue nil

        # Modify only fragment-only links
        next if uri.nil? || uri.absolute? || !uri.path.blank?

        # Abort if there is not a target or it's still present in this fragment
        target = uri.fragment
        next if target.blank? || node.at_css("##{target}, [name=\"#{target}\"]")

        # Change the link to point to the reference view
        href.value = "#{reference_view_url}##{target}"
      end unless reference_view_url.nil?

      @to_html = node.to_html
    end

    def blank?
      to_html.blank?
    end
  end
end
