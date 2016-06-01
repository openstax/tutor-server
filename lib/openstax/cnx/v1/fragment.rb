class OpenStax::Cnx::V1::Fragment

  attr_reader :node, :labels

  def initialize(node:, title: nil, labels: nil)
    @node   = node
    @title  = title
    @labels = labels
  end

  def title
    nil
  end

  def node_id
    @node_id ||= node.attribute('id').try :value
  end

  def labels
    @labels || []
  end

  def blank?
    false
  end

end
