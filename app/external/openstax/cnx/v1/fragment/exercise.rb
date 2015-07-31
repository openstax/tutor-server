module OpenStax::Cnx::V1::Fragment
  class Exercise
    include ActsAsFragment

    # Used to get the title
    TITLE_CSS = '[data-type="title"]'

    # For fragments missing a proper title
    DEFAULT_TITLE = nil

    # CSS to find the exercise embed code attribute
    EMBED_CODE_CSS = 'a[href^="#ost/api/ex/"]'

    # Regex to extract the appropriate tag from the embed code
    EMBED_TAG_REGEX = /\A#ost\/api\/ex\/([\w-]+)\z/

    # xpath to find the exercise embed code after url is absolutized
    ABSOLUTE_EMBED_CODE_XPATH = './/a[contains(@href, "/api/exercises")]'

    # Regex to extract the appropriate tag from absolutized url
    ABSOLUTE_EMBED_TAG_REGEX = /q=tag(?::|%3A)([\w-]+)$/

    def initialize(node:, title: nil, short_code: nil)
      @node       = node
      @title      = title
      @short_code = short_code

      # Absolutized exercise url
      self.class.absolutize_url(@node)
    end

    attr_reader :node

    def title
      @title ||= node.at_css(TITLE_CSS).try(:content).try(:strip) || DEFAULT_TITLE
    end

    def embed_code
      @embed_code ||= node.at_xpath(ABSOLUTE_EMBED_CODE_XPATH).try(:attribute, 'href').try(:value)
    end

    def embed_tag
      @short_code ||= ABSOLUTE_EMBED_TAG_REGEX.match(embed_code).try(:[], 1)
    end

    def exercise?
      true
    end

    def self.absolutize_url(node)
      link = node.at_css(EMBED_CODE_CSS)
      return if link.nil?

      href = link.attribute('href')
      return if href.nil?

      exercises_url = OpenStax::Exercises::V1.configuration.server_url
      uri = Addressable::URI.join(exercises_url, '/api/exercises')

      short_code = EMBED_TAG_REGEX.match(href.value).try(:[], 1)
      uri.query_values = { q: "tag:#{short_code}" }
      href.value = uri.to_s
    end

  end
end
