module OpenStax::Cnx::V1::Fragment
  class Exercise

    # Used to get the title
    TITLE_CSS = "[data-type='title']"

    # For fragments missing a proper title
    DEFAULT_TITLE = nil

    # CSS to find the exercise short code attribute
    SHORT_CODE_CSS = 'a[href~=\#ost\/api\/ex\/]'

    # Regex to extract the appropriate short code from the above attribute
    SHORT_CODE_REGEX = /\A#ost\/api\/ex\/([\w-]+)\z/

    def initialize(node:, title: nil, short_code: nil)
      @node       = node
      @title      = title
      @short_code = short_code
    end

    def title
      @title ||= @node.at_css(TITLE_CSS).try(:content) || DEFAULT_TITLE
    end

    def short_code
      return @short_code unless @short_code.nil?

      link = @node.at_css(SHORT_CODE_CSS).try(:value)
      @short_code ||= SHORT_CODE_REGEX.match(link).try(:[], 1)
    end

    def to_s(indent: 0)
      s = "#{' '*indent}EXERCISE #{title} // #{@id}\n"
    end

  end
end
