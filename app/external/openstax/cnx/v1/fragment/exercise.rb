module OpenStax::Cnx::V1::Fragment
  class Exercise

    # Used to get the title
    TITLE_CSS = '[data-type="title"]'

    # For fragments missing a proper title
    DEFAULT_TITLE = nil

    # CSS to find the exercise embed code attribute
    EMBED_CODE_CSS = 'a[href^="#ost/api/ex/"]'

    # Regex to extract the appropriate tag from the embed code
    EMBED_TAG_REGEX = /\A#ost\/api\/ex\/([\w-]+)\z/

    def initialize(node:, title: nil, short_code: nil)
      @node       = node
      @title      = title
      @short_code = short_code
    end

    attr_reader :node

    def title
      @title ||= node.at_css(TITLE_CSS).try(:content).try(:strip) || \
                 DEFAULT_TITLE
    end

    def embed_code
      @embed_code ||= node.at_css(EMBED_CODE_CSS).try(:attributes)
                                                 .try(:[], 'href')
    end

    def embed_tag
      @short_code ||= EMBED_TAG_REGEX.match(embed_code).try(:[], 1)
    end

    def to_s(indent: 0)
      s = "#{' '*indent}EXERCISE #{title} // #{embed_tag}\n"
    end

  end
end
