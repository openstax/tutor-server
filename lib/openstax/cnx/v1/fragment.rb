# All fragment subclasses must be serializable with to_yaml and YAML.load
# Nokogiri nodes are not serializable, so they must be processed in the initialize method
class OpenStax::Cnx::V1::Fragment
  attr_reader :title, :labels, :node_id

  def initialize(node:, title: nil, labels: nil)
    @title  = title
    @labels = labels || []
    @node_id = node.attribute('id').try :value
  end

  def blank?
    false
  end
end
