# All fragment subclasses must be serializable with to_yaml and YAML.load
# Nokogiri nodes are not serializable, so they must be processed in the initialize method
class OpenStax::Cnx::V1::Fragment
  attr_reader :title, :labels, :node_id

  def initialize(node:, title: nil, labels: nil)
    @title  = title
    @labels = labels || []
    @node_id = node[:id]
  end

  def blank?
    false
  end

  def node
    raise "#{self.class.name} has no content" unless respond_to?(:to_html)

    Nokogiri::HTML to_html
  end

  def has_css?(css, custom_css)
    return false unless respond_to?(:to_html)

    !node.at_css(css, custom_css).nil?
  end

  def append(new_node)
    content_node = node
    content_node.add_next_sibling new_node
    @to_html = content_node.to_html
  end
end
