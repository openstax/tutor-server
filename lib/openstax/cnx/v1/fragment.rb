class OpenStax::Cnx::V1::Fragment

  # Used to get the title
  TITLE_CSS = '[data-type="title"]'

  attr_reader :node, :labels

  def initialize(node:, title: nil, labels: nil)
    @node   = node
    @title  = title
    @labels = labels
  end

  def title
    return @title unless @title.nil?

    title_matches = node.css(TITLE_CSS)
    @title = title_matches.empty? ? nil : title_matches.map{ |nd| nd.content.strip }.uniq.join('; ')
  end

  def labels
    @labels || []
  end

  def exercise?
    false
  end

end
