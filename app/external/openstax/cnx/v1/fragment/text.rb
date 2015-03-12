module OpenStax::Cnx::V1::Fragment
  class Text

    # Used to get the title
    TITLE_CSS = "*[data-type='title']"

    # For fragments missing a proper title
    DEFAULT_TITLE = nil

    def initialize(node:, title: nil)
      @node  = node
      @title = title
    end

    def title
      return @title unless @title.nil?

      @title = @node.css(TITLE_CSS).collect{|n| n.try(:content)}
                                   .compact.join(', ')
      @title = DEFAULT_TITLE if @title.blank?
      @title
    end

    def to_html
      @node.to_html
    end

    def to_s(indent: 0)
      s = "#{' '*indent}TEXT #{title} // #{@id}\n"
    end

  end
end
