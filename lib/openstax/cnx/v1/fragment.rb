class OpenStax::Cnx::V1::Fragment

  # Used to get the title
  TITLE_CSS = '[data-type="title"]'

  # For fragments missing a proper title
  DEFAULT_TITLE = nil

  attr_reader :node, :labels

  def initialize(node:, title: nil, labels: [])
    @node   = node
    @title  = title
    @labels = labels
  end

  def title
    return @title unless @title.nil?

    @title = node.css(TITLE_CSS).map{|n| n.try(:content).try(:strip)}
                                .compact.uniq.join('; ')
    @title = DEFAULT_TITLE if @title.blank?
    @title
  end

  def exercise?
    false
  end

end
